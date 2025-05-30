// lib/services/logging_service.dart

import 'dart:io';

/// LoggingService creates a logs/ directory and a timestamped log file
/// per application run, exposing logToFile() to append messages.
class LoggingService {
  static const _dirName = 'logs';
  static const _filePrefix = 'camwork_';

  late final Directory logsDir;
  late final File _logFile;

  LoggingService({String basePath = '.'})
      : logsDir = Directory('$basePath/$_dirName');

  /// Initializes logs/ folder and creates a .log file with timestamp.
  Future<void> init() async {
    if (!logsDir.existsSync()) {
      logsDir.createSync(recursive: true);
    }
    final now = DateTime.now();
    final stamp = '${now.year}-${now.month.toString().padLeft(2,'0')}-'
                  '${now.day.toString().padLeft(2,'0')}_'
                  '${now.hour.toString().padLeft(2,'0')}'
                  '${now.minute.toString().padLeft(2,'0')}'
                  '${now.second.toString().padLeft(2,'0')}';
    _logFile = File('${logsDir.path}/$_filePrefix$stamp.log')..createSync();
  }

  /// Appends a timestamped message to the current log file.
  void logToFile(String message) {
    final timestamp = DateTime.now().toIso8601String();
    _logFile.writeAsStringSync('[$timestamp] $message\n', mode: FileMode.append);
  }
}
