// lib/services/config_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// ConfigService persists and retrieves application settings,
/// such as the CAMERAS root directory path.
class ConfigService {
  static const _keyCamerasPath = 'cameras_path';

  /// Returns the stored CAMERAS path, or null if not set.
  Future<String?> getCamerasPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCamerasPath);
  }

  /// Saves the CAMERAS path for future runs.
  Future<void> setCamerasPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCamerasPath, path);
  }
}
