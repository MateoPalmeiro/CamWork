// lib/services/raw_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/file_utils.dart';

/// Service for moving raw files (.cr2, .arw) into RAW/ subfolders
/// under each thematic and sub-thematic folder.
class RawService {
  final Directory camerasDir;

  RawService(this.camerasDir);

  /// Separates raw files:
  /// - Finds all model → YYYY.MM → Theme/Subtheme directories.
  /// - In each, moves any raw files into a RAW/ folder.
  Future<void> separateRaw({
    required void Function(String) onLog,
    required void Function(double) onProgress,
  }) async {
    // List all model folders
    final modelDirs = camerasDir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path) != 'PRIVATE')
        .toList();

    int totalModels = modelDirs.length;
    int processedModels = 0;

    for (final modelDir in modelDirs) {
      onLog('Processing model: ${modelDir.path}');
      // Find YYYY.MM folders
      final dateDirs = modelDir.listSync()
          .whereType<Directory>()
          .where((d) => RegExp(r'^\d{4}\.\d{2}$').hasMatch(p.basename(d.path)))
          .toList();

      for (final dateDir in dateDirs) {
        // First process themes at this level
        final themeDirs = dateDir.listSync()
            .whereType<Directory>()
            .where((d) => p.basename(d.path).toLowerCase() != 'raw')
            .toList();

        for (final themeDir in themeDirs) {
          _processRawInDirectory(themeDir, onLog);
          // Then process subthemes
          final subthemeDirs = themeDir.listSync()
              .whereType<Directory>()
              .where((d) => p.basename(d.path).toLowerCase() != 'raw')
              .toList();
          for (final sub in subthemeDirs) {
            _processRawInDirectory(sub, onLog);
          }
        }
      }

      processedModels++;
      onProgress(processedModels / totalModels);
    }

    onLog('RAW separation complete.');
  }

  /// Moves any raw files in [dir] into a RAW/ subfolder.
  void _processRawInDirectory(Directory dir, void Function(String) onLog) {
    final rawFiles = dir.listSync()
        .whereType<File>()
        .where((f) => FileUtils.isRaw(f))
        .toList();
    if (rawFiles.isEmpty) {
      onLog('  No RAW files in ${dir.path}');
      return;
    }

    final rawDir = Directory(p.join(dir.path, 'RAW'));
    if (!rawDir.existsSync()) {
      rawDir.createSync();
      onLog('  Created RAW folder: ${rawDir.path}');
    }

    for (final file in rawFiles) {
      final destPath = p.join(rawDir.path, p.basename(file.path));
      FileUtils.moveFileSafe(file, File(destPath));
      onLog('  Moved RAW file: $destPath');
    }
  }
}
