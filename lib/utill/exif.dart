// lib/utils/exif.dart

import 'dart:io';

/// ExifToolkit wraps calls to the ExifTool CLI to extract metadata.
/// Requires `exiftool` to be installed and available on the system PATH.
class ExifToolkit {
  /// Reads the camera model from EXIF metadata.
  /// Returns a string like "Canon EOS 650D" or "Unknown" on failure.
  static Future<String> readCameraModel(File file) async {
    try {
      final result = await Process.run(
        'exiftool',
        ['-s3', '-Make', '-Model', file.path],
      );
      if (result.exitCode == 0) {
        final lines = (result.stdout as String).trim().split('\n');
        if (lines.length >= 2 && lines[0].isNotEmpty && lines[1].isNotEmpty) {
          return '${lines[0].trim()} ${lines[1].trim()}';
        }
        if (lines.isNotEmpty && lines[0].isNotEmpty) {
          return lines[0].trim();
        }
      }
    } catch (_) {
      // Fall through to return Unknown
    }
    return 'Unknown';
  }

  /// Reads the DateTimeOriginal field from EXIF metadata.
  /// Returns a [DateTime] or null if unavailable or on error.
  static Future<DateTime?> readDateTimeOriginal(File file) async {
    try {
      final result = await Process.run(
        'exiftool',
        ['-s3', '-DateTimeOriginal', file.path],
      );
      if (result.exitCode == 0) {
        final raw = (result.stdout as String).trim();
        if (raw.isNotEmpty) {
          // EXIF format: "YYYY:MM:DD HH:MM:SS"
          final parts = raw.split(' ');
          final datePart = parts[0].replaceAll(':', '-');
          final timePart = parts.length > 1 ? parts[1] : '00:00:00';
          return DateTime.parse('$datePart $timePart');
        }
      }
    } catch (_) {
      // Ignore and return null
    }
    return null;
  }
}
