// lib/services/duplicate_service.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Service to detect exact bit-wise duplicates within each camera model folder,
/// and to provide duplicate groups for preview.
class DuplicateService {
  final Directory camerasDir;

  DuplicateService(this.camerasDir);

  /// Original scan method: logs duplicates as text.
  Future<void> findDuplicates({
    required void Function(String) onLog,
    required void Function(double) onProgress,
  }) async {
    final modelDirs = camerasDir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path) != 'PRIVATE')
        .toList();

    int totalModels = modelDirs.length;
    int processedModels = 0;

    for (final modelDir in modelDirs) {
      onLog('Scanning model: ${modelDir.path}');
      final files = modelDir.listSync(recursive: true).whereType<File>().toList();

      // Group by filename
      final Map<String, List<File>> groups = {};
      for (final file in files) {
        final key = p.basename(file.path).toLowerCase();
        groups.putIfAbsent(key, () => []).add(file);
      }

      // For each group >1, hash and log duplicates
      for (final entry in groups.entries) {
        if (entry.value.length < 2) continue;
        onLog('Comparing group: ${entry.key} (${entry.value.length} files)');
        final Map<String, List<String>> hashMap = {};
        for (final file in entry.value) {
          onLog('  Hashing ${file.path}');
          final bytes = file.readAsBytesSync();
          final hash = sha256.convert(bytes).toString();
          hashMap.putIfAbsent(hash, () => []).add(file.path);
        }
        for (final hEntry in hashMap.entries) {
          if (hEntry.value.length > 1) {
            onLog('  Duplicate hash ${hEntry.key}:');
            for (final path in hEntry.value) {
              onLog('    - $path');
            }
          }
        }
      }

      processedModels++;
      onProgress(processedModels / totalModels);
    }

    onLog('Duplicate scan complete.');
  }

  /// New method: returns groups of duplicate files for UI preview.
  Future<List<List<File>>> findDuplicateGroups() async {
    final groups = <List<File>>[];

    final modelDirs = camerasDir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path) != 'PRIVATE')
        .toList();

    for (final modelDir in modelDirs) {
      final files = modelDir.listSync(recursive: true).whereType<File>().toList();

      // Group by filename
      final Map<String, List<File>> nameMap = {};
      for (final file in files) {
        final key = p.basename(file.path).toLowerCase();
        nameMap.putIfAbsent(key, () => []).add(file);
      }

      // For each group >1, compute SHA256
      for (final entry in nameMap.entries.where((e) => e.value.length > 1)) {
        final hashMap = <String, File>{};
        for (final file in entry.value) {
          final bytes = file.readAsBytesSync();
          final hash = sha256.convert(bytes).toString();
          if (hashMap.containsKey(hash)) {
            final existing = hashMap[hash]!;
            // find or create a group containing `existing`
            var group = groups.firstWhere(
              (g) => g.contains(existing),
              orElse: () {
                final newGroup = [existing];
                groups.add(newGroup);
                return newGroup;
              },
            );
            group.add(file);
          } else {
            hashMap[hash] = file;
          }
        }
      }
    }

    return groups;
  }
}
