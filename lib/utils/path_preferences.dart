// lib/utils/path_preferences.dart

import 'package:shared_preferences/shared_preferences.dart';

/// PathPreferences provides a generic wrapper around SharedPreferences
/// for storing and retrieving filesystem paths.
class PathPreferences {
  /// Stores [path] under the given [key].
  static Future<void> setPath(String key, String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, path);
  }

  /// Retrieves the stored path for [key], or null if none is set.
  static Future<String?> getPath(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}
