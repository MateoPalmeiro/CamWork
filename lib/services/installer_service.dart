import 'dart:io';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

enum InstallMode { interactive, silent }

class InstallerService {
  final Logger _logger = Logger('InstallerService');
  final InstallMode mode;

  InstallerService({this.mode = InstallMode.interactive});

  /// Comprueba si un comando existe en PATH
  Future<bool> _isOnPath(String command, List<String> args) async {
    try {
      final result = await Process.run(command, args);
      return result.exitCode == 0;
    } catch (_) {
      return false;
    }
  }

  /// Comprueba todas las dependencias y devuelve un mapa
  Future<Map<String, bool>> checkDependencies() async {
    final checks = <String, Future<bool>>{
      'python': _isOnPath('python', ['--version']),
      'exiftool': _isOnPath('exiftool', ['-ver']),
      'flutter': _isOnPath('flutter', ['--version']),
    };
    final results = <String, bool>{};
    for (var entry in checks.entries) {
      results[entry.key] = await entry.value;
      _logger.info('Dependency ${entry.key}: ${results[entry.key]}');
    }
    return results;
  }

  /// En modo interactive muestra diálogos para instalar lo que falte
  Future<void> handleInteractive(BuildContext context) async {
    final deps = await checkDependencies();
    final missing = deps.entries.where((e) => !e.value).map((e) => e.key).toList();
    if (missing.isEmpty) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Dependencias faltantes'),
        content: Text('Faltan: ${missing.join(', ')}.\n¿Quieres abrir la web de instalación?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('Descargar'),
            onPressed: () {
              for (var dep in missing) {
                _openInstallPage(dep);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// En modo silent lanza excepción si falta algo
  Future<void> handleSilent() async {
    final deps = await checkDependencies();
    final missing = deps.entries.where((e) => !e.value).map((e) => e.key).toList();
    if (missing.isNotEmpty) {
      _logger.severe('Dependencias faltantes: ${missing.join(', ')}');
      exit(1);
    }
  }

  /// Abre el navegador a la página de descarga de cada dependencia
  void _openInstallPage(String dep) {
    final urls = {
      'python': 'https://www.python.org/downloads/windows/',
      'exiftool': 'https://exiftool.org/',
      'flutter': 'https://flutter.dev/docs/get-started/install/windows',
    };
    final url = urls[dep];
    if (url != null) Process.run('start', [url], runInShell: true);
  }
}
