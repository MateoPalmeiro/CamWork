// lib/services/stats_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;
import '../utils/pdf_report.dart';

/// Experimental StatsService: analyzes the media collection and
/// generates a PDF report with counts by model and extension.
class StatsService {
  final Directory camerasDir;

  StatsService(this.camerasDir);

  Future<void> generateStatistics({
    required void Function(String) onLog,
    required void Function(double) onProgress,
  }) async {
    onLog('Starting statistics generation (experimental)...');

    // 1) Scan models
    final modelDirs = camerasDir
        .listSync()
        .whereType<Directory>()
        .where((d) => p.basename(d.path) != 'PRIVATE')
        .toList();

    final Map<String, int> modelCounts = {};
    final Map<String, int> extCounts = {};

    int totalModels = modelDirs.length;
    int doneModels = 0;

    for (final modelDir in modelDirs) {
      final modelName = p.basename(modelDir.path);
      int count = 0;

      for (final file in modelDir.listSync(recursive: true).whereType<File>()) {
        count++;
        final ext = p.extension(file.path).toLowerCase();
        extCounts[ext] = (extCounts[ext] ?? 0) + 1;
      }

      modelCounts[modelName] = count;
      onLog('Model $modelName has $count files.');
      doneModels++;
      onProgress(doneModels / totalModels);
    }

    // 2) Generate PDF
    await PdfReport.generateStatisticsReport(
      outputDir: Directory('pdf'),
      modelCounts: modelCounts,
      extCounts: extCounts,
    );
    onLog('Statistics PDF generated.');
  }
}
