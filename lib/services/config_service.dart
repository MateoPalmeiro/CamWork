// lib/services/config_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// ConfigService persiste y recupera la ruta raíz de la aplicación.
/// De ahí derivamos la ruta a CAMERAS/ automáticamente.
class ConfigService {
  static const _keyRootPath = 'root_path';

  /// Devuelve la ruta raíz configurada, o null si no está establecida.
  Future<String?> getRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRootPath);
  }

  /// Guarda la ruta raíz de la aplicación.
  Future<void> setRootPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRootPath, path);
  }

  /// Devuelve la ruta a la carpeta CAMERAS/ dentro de la ruta raíz, o null si no hay root.
  Future<String?> getCamerasPath() async {
    final root = await getRootPath();
    if (root == null) return null;
    return '$root/CAMERAS';
  }
}
