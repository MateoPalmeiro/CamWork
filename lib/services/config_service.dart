// lib/services/config_service.dart

import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// ConfigService persiste y recupera la ruta raíz de la aplicación.
/// De ahí derivamos la ruta a CAMERAS/ automáticamente.
class ConfigService {
  static const _keyRootPath = 'root_path';

  /// Devuelve la ruta raíz configurada, o null si no está establecida.
  Future<String?> getRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRootPath)?.trim();
  }

  /// Guarda la ruta raíz de la aplicación (limpiando comillas sobrantes).
  Future<void> setRootPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    // Eliminamos comillas dobles y simples
    final cleaned = path.trim().replaceAll('"', '').replaceAll("'", '').trim();
    await prefs.setString(_keyRootPath, cleaned);
  }

  /// Elimina la ruta raíz guardada (para hacer un reset).
  Future<void> clearRootPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRootPath);
  }

  /// Devuelve la ruta a la carpeta CAMERAS/ dentro de la ruta raíz, o null si no hay root.
  Future<String?> getCamerasPath() async {
    final root = await getRootPath();
    if (root == null) return null;
    // Usamos siempre '/' ya que SharedPreferences almacena en string,
    // y Dart/Flutter lo normaliza según plataforma al usar Directory.
    return '$root${Platform.pathSeparator}CAMERAS';
  }
}
