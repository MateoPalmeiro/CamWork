// lib/services/duplicate_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Service to detect exact bit-wise duplicates within each camera model folder.
class DuplicateService {
  final Directory camerasDir;

  DuplicateService(this.camerasDir);

  /// Finds duplicates:
  /// - Groups files by name+extension.
  /// - For groups of size>1, computes SHA256 and logs identical pairs.
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
      // Collect all files under this model
      final files = modelDir
          .listSync(recursive: true)
          .whereType<File>()
          .toList();

      // Map basename.ext -> list of files
      final Map<String, List<File>> groups = {};
      for (final file in files) {
        final key = p.basename(file.path).toLowerCase();
        groups.putIfAbsent(key, () => []).add(file);
      }

      // For each group >1, compute SHA256
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
        // Report identical hashes
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
}
