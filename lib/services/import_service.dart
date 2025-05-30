// lib/services/import_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/exif.dart';
import '../utils/file_utils.dart';
import '../utils/pdf_report.dart';

class ImportService {
  final Directory sourceDir;
  final Directory camerasDir;

  ImportService({
    required this.sourceDir,
    required this.camerasDir,
  });

  /// askFolderForModel: pide la carpeta destino para cada modelo EXIF.
  Future<void> runImport({
    required Future<String> Function(String model) askFolderForModel,
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
      onLog('No photo files found.');
      return;
    }

    var processed = 0;
    for (final file in files) {
      try {
        // 1) Modelo EXIF
        final model = await ExifToolkit.readCameraModel(file);
        final folderName = await askFolderForModel(model);
        final modelDir = Directory(p.join(camerasDir.path, folderName));
        if (!modelDir.existsSync()) {
          modelDir.createSync(recursive: true);
          onLog('Created model folder: ${modelDir.path}');
        }

        // 2) Mover a CAMERAS/<folderName>
        final intermediate = p.join(modelDir.path, p.basename(file.path));
        FileUtils.moveFileSafe(file, File(intermediate));
        onLog('Moved to model folder: $intermediate');

        // 3) Fecha EXIF o fallback
        final dt = await ExifToolkit.readDateTimeOriginal(File(intermediate))
            ?? FileUtils.fileDate(File(intermediate));
        final adj = FileUtils.adjustMonth(dt);

        // 4) Mover a YYYY.MM
        final yymm = '${adj.year}.${adj.month.toString().padLeft(2, '0')}';
        final dateDir = Directory(p.join(modelDir.path, yymm));
        if (!dateDir.existsSync()) dateDir.createSync();
        final finalPath = p.join(dateDir.path, p.basename(intermediate));
        FileUtils.moveFileSafe(File(intermediate), File(finalPath));
        onLog('Moved to date folder: $finalPath');

      } catch (e) {
        onLog('Error processing ${file.path}: $e');
      }

      processed++;
      onProgress(processed / total);
    }

    // Generar resumen PDF
    await PdfReport.generateImportSummary(
      outputDir: Directory('pdf'),
      logLines: [], // opcional: pasar logs
    );
    onLog('Import complete. PDF summary generated.');
  }
}
