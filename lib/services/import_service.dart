// lib/services/import_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/exif.dart';
import '../utils/file_utils.dart';
import '../utils/pdf_report.dart';

/// Service that handles both model sorting and date-based grouping.
/// Moves photos from a source directory into CAMERAS/<model>/YYYY.MM/.
class ImportService {
  final Directory sourceDir;
  final Directory camerasDir;

  ImportService({
    required this.sourceDir,
    required this.camerasDir,
  });

  /// Executes the import workflow.
  /// - onLog: callback for status messages.
  /// - onProgress: callback for progress (0.0–1.0).
  Future<void> runImport({
    required void Function(String) onLog,
    required void Function(double) onProgress,
  }) async {
    final files = sourceDir
        .listSync()
        .whereType<File>()
        .where(FileUtils.isPhoto)
        .toList();

    final total = files.length;
    if (total == 0) {
      onLog('No photo files found in source directory.');
      return;
    }

    var processed = 0;
    for (final file in files) {
      try {
        // 1) Read EXIF camera model
        final model = await ExifToolkit.readCameraModel(file);
        final modelDir = Directory(p.join(camerasDir.path, model));
        if (!modelDir.existsSync()) {
          modelDir.createSync(recursive: true);
          onLog('Created model folder: ${modelDir.path}');
        }

        // 2) Move file to model folder
        final destModelPath = p.join(modelDir.path, p.basename(file.path));
        FileUtils.moveFileSafe(file, File(destModelPath));
        onLog('Moved to model folder: $destModelPath');

        // 3) Read EXIF date or fallback
        final dt = await ExifToolkit.readDateTimeOriginal(File(destModelPath)) ??
            FileUtils.fileDate(File(destModelPath));

        // 4) Adjust month boundary
        final adj = FileUtils.adjustMonth(dt);

        // 5) Create YYYY.MM folder and move there
        final dateFolderName = '${adj.year}.${adj.month.toString().padLeft(2, '0')}';
        final dateDir = Directory(p.join(modelDir.path, dateFolderName));
        if (!dateDir.existsSync()) dateDir.createSync();
        final destDatePath = p.join(dateDir.path, p.basename(destModelPath));
        FileUtils.moveFileSafe(File(destModelPath), File(destDatePath));
        onLog('Moved to date folder: $destDatePath');
      } catch (e) {
        onLog('Error processing ${file.path}: $e');
      }

      processed++;
      onProgress(processed / total);
    }

    // 6) Generate PDF summary
    await PdfReport.generateImportSummary(
      outputDir: Directory('pdf'),
      logLines: const [], // could pass collected logs here
    );
    onLog('Import complete. PDF summary generated.');
  }
}
