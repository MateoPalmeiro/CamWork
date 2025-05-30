// lib/services/import_service.dart

import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../services/mapping_service.dart';
import '../services/hash_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

typedef AskFolderCallback = Future<String> Function(String model);
typedef LogCallback = void Function(String message);
typedef ProgressCallback = void Function(double progress);
typedef ErrorCallback = void Function(String error);

class ImportService {
  final Directory sourceDir;
  final Directory camerasDir;
  final MappingService mappingService;
  final HashService hashService;
  final ConfigService configService;
  final LoggingService loggingService;

  ImportService({
    required this.sourceDir,
    required this.camerasDir,
    required this.mappingService,
    required this.hashService,
    required this.configService,
    required this.loggingService,
  });

  Future<void> runImport({
    required AskFolderCallback askFolderForModel,
    required LogCallback onLog,
    required ProgressCallback onProgress,
    required ErrorCallback onError,
    bool dryRun = false,
  }) async {
    await mappingService.init();
    await hashService.init();

    final files = sourceDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
          final ext = f.path.toLowerCase();
          return ext.endsWith('.jpg') ||
                 ext.endsWith('.jpeg') ||
                 ext.endsWith('.png');
        })
        .toList();

    final total = files.length;
    var count = 0;

    for (var file in files) {
      try {
        final bytes = await file.readAsBytes();
        final hash = sha256.convert(bytes).toString();

        if (hashService.isProcessed(hash)) {
          onLog('Skipping already imported: ${file.path}');
        } else {
          final model = await _readExifModel(file);
          final folderName = await askFolderForModel(model);

          final date = await _readExifDate(file);
          final monthDir = _computeMonthDir(date);
          final destDir = Directory('${camerasDir.path}/$folderName/$monthDir');
          final destPath = '${destDir.path}${Platform.pathSeparator}${file.uri.pathSegments.last}';

          onLog('${dryRun ? '[Dry-run] Would move' : 'Moving'}: ${file.path} → $destPath');

          if (!dryRun) {
            if (!destDir.existsSync()) destDir.createSync(recursive: true);
            await file.rename(destPath);
            hashService.add(hash);
          }
        }
      } catch (e) {
        final msg = 'Error processing ${file.path}: $e';
        onLog(msg);
        onError(msg);
      }

      count++;
      onProgress(count / total);
    }

    if (!dryRun) {
      await hashService.persist();
      onLog('Import complete. Hash registry updated.');
    } else {
      onLog('Dry-run complete. No files were moved.');
    }
  }

  Future<String> _readExifModel(File file) async {
    try {
      final result = await Process.run('exiftool', ['-j', '-Model', file.path]);
      if (result.exitCode == 0) {
        final List<dynamic> jsonList = jsonDecode(result.stdout as String);
        if (jsonList.isNotEmpty && jsonList.first['Model'] != null) {
          return (jsonList.first['Model'] as String).trim();
        }
      }
    } catch (_) {}
    return 'UnknownModel';
  }

  Future<DateTime> _readExifDate(File file) async {
    try {
      final result = await Process.run(
        'exiftool',
        ['-j', '-DateTimeOriginal', '-d', '%Y:%m:%d %H:%M:%S', file.path],
      );
      if (result.exitCode == 0) {
        final List<dynamic> jsonList = jsonDecode(result.stdout as String);
        if (jsonList.isNotEmpty && jsonList.first['DateTimeOriginal'] != null) {
          final dtString = jsonList.first['DateTimeOriginal'] as String;
          // dtString: "YYYY:MM:DD HH:MM:SS"
          final parts = dtString.split(' ');
          final datePart = parts[0].replaceAll(':', '-');        // "YYYY-MM-DD"
          final timePart = parts[1];                              // "HH:MM:SS"
          return DateTime.parse('$datePart' 'T' '$timePart');
        }
      }
    } catch (_) {}
    return file.lastModifiedSync();
  }

  String _computeMonthDir(DateTime dt) {
    var d = dt;
    if (dt.day == 1 && dt.hour < 8) {
      d = dt.subtract(Duration(days: 1));
    }
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$y.$m';
  }
}
