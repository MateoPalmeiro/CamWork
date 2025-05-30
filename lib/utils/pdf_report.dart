// lib/utils/pdf_report.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path/path.dart' as p;

/// PdfReport provides utilities to create PDF summaries.
class PdfReport {
  /// Generates a simple PDF listing each line in [logLines].
  /// Saves to [outputFile].
  static Future<void> generateStatsSummary({
    required File outputFile,
    required List<String> logLines,
  }) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text('Statistics Summary')),
          pw.Paragraph(text: 'Generated on: ${DateTime.now()}'),
          pw.SizedBox(height: 10),
          ...logLines.map((line) => pw.Text(line)).toList(),
        ],
      ),
    );
    Uint8List bytes = await pdf.save();
    await outputFile.writeAsBytes(bytes);
  }

  /// Generates a PDF report with counts per model and per extension.
  static Future<void> generateStatisticsReport({
    required Directory outputDir,
    required Map<String, int> modelCounts,
    required Map<String, int> extCounts,
  }) async {
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);
    final filename = p.join(
      outputDir.path,
      'statistics_report_${DateTime.now().toIso8601String()}.pdf',
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text('Statistics Report')),
          pw.Paragraph(text: 'Generated on: ${DateTime.now()}'),
          pw.SizedBox(height: 10),
          pw.Text('Files per Camera Model:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ...modelCounts.entries.map((e) => pw.Text('${e.key}: ${e.value} files')),
          pw.SizedBox(height: 20),
          pw.Text('Files per Extension:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ...extCounts.entries.map((e) => pw.Text('${e.key}: ${e.value}')),
        ],
      ),
    );
    Uint8List bytes = await pdf.save();
    await File(filename).writeAsBytes(bytes);
  }

  /// Generates a PDF summarizing an import run with the provided [logLines].
  /// Writes into [outputDir]/import_summary_<timestamp>.pdf.
  static Future<void> generateImportSummary({
    required Directory outputDir,
    required List<String> logLines,
  }) async {
    if (!outputDir.existsSync()) outputDir.createSync(recursive: true);
    final filename = p.join(
      outputDir.path,
      'import_summary_${DateTime.now().toIso8601String()}.pdf',
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => <pw.Widget>[
          pw.Header(level: 0, child: pw.Text('Import Summary')),
          pw.Paragraph(text: 'Imported on: ${DateTime.now()}'),
          pw.SizedBox(height: 10),
          ...logLines.map((line) => pw.Text(line)).toList(),
        ],
      ),
    );
    Uint8List bytes = await pdf.save();
    await File(filename).writeAsBytes(bytes);
  }
}
