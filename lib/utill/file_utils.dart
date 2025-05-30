// lib/utils/file_utils.dart

import 'dart:io';

/// Supported extensions for images and RAW files.
const _photoExts = {'.jpg', '.jpeg', '.png'};
const _rawExts = {'.cr2', '.arw'};

/// FileUtils provides common filesystem helpers.
class FileUtils {
  /// Returns true if [file] has an image extension.
  static bool isPhoto(File file) {
    final ext = file.path.toLowerCase().split('.').last;
    return _photoExts.contains('.$ext');
  }

  /// Returns true if [file] has a RAW extension.
  static bool isRaw(File file) {
    final ext = file.path.toLowerCase().split('.').last;
    return _rawExts.contains('.$ext');
  }

  /// Adjusts the date so that files shot on the 1st before 08:00 belong to the previous month.
  static DateTime adjustMonth(DateTime dt) {
    if (dt.day == 1 && dt.hour < 8) {
      return dt.subtract(const Duration(days: 1));
    }
    return dt;
  }

  /// Fallback for capture date: uses file system's change timestamp.
  static DateTime fileDate(File file) {
    final stat = file.statSync();
    return stat.changed;
  }

  /// Moves [src] to [dest] only if [dest] does not already exist.
  /// Logs/duplicates must be handled by the caller.
  static void moveFileSafe(File src, File dest) {
    if (dest.existsSync()) {
      return;
    }
    src.renameSync(dest);
  }
}
