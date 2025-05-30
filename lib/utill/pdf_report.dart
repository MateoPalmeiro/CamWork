// lib/utils/pdf_report.dart

import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// PdfReport generates PDF summaries and reports using the `pdf` package.
class PdfReport {
  /// Generates a simple import summary PDF.
  static Future<void> generateImportSummary({
    required Directory outputDir,
    required List<String> logLines,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Import Summary', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 12),
            ...logLines.map((l) => pw.Text(l)),
          ],
        ),
      ),
    );
    final file = File('${outputDir.path}/import_summary.pdf');
    await file.writeAsBytes(await pdf.save());
  }

  /// Generates a statistics report PDF with model and extension counts.
  static Future<void> generateStatisticsReport({
    required Directory outputDir,
    required Map<String, int> modelCounts,
    required Map<String, int> extCounts,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text('Statistics Report', style: pw.TextStyle(fontSize: 24)),
          pw.SizedBox(height: 12),
          pw.Text('Model Counts:', style: pw.TextStyle(fontSize: 18)),
          pw.Bullet(
            text: modelCounts.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
          ),
          pw.SizedBox(height: 8),
          pw.Text('Extension Counts:', style: pw.TextStyle(fontSize: 18)),
          pw.Bullet(
            text: extCounts.entries
                .map((e) => '${e.key}: ${e.value}')
                .join('\n'),
          ),
        ],
      ),
    );
    final file = File('${outputDir.path}/statistics_report.pdf');
    await file.writeAsBytes(await pdf.save());
  }
}
