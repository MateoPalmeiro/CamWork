import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
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

  /// Escanea, gestiona hashing y mueve (o solo simula si dryRun=true).
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

    for (final file in files) {
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

          // Construimos rutas de forma segura con path.join
          final destDirPath = p.join(camerasDir.path, folderName, monthDir);
          final destDir = Directory(destDirPath);
          final destPath = p.join(destDirPath, p.basename(file.path));

          onLog('${dryRun ? '[Dry-run] Would move' : 'Moving'}: '
                '${file.path} → $destPath');

          if (!dryRun) {
            if (!destDir.existsSync()) {
              destDir.createSync(recursive: true);
            }
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
        final model = jsonList.first['Model'] as String?;
        if (model != null && model.trim().isNotEmpty) {
          return model.trim();
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
        final dtString = jsonList.first['DateTimeOriginal'] as String?;
        if (dtString != null) {
          // Convertimos "YYYY:MM:DD HH:MM:SS" a DateTime
          final normalized = dtString.replaceFirst(':', '-').replaceFirst(':', '-');
          return DateTime.parse(normalized.replaceFirst(' ', 'T'));
        }
      }
    } catch (_) {}
    return file.lastModifiedSync();
  }

  String _computeMonthDir(DateTime dt) {
    var d = dt;
    if (d.day == 1 && d.hour < 8) {
      d = d.subtract(const Duration(days: 1));
    }
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$y.$m';
  }
}
