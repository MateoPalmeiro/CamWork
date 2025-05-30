// lib/services/hash_service.dart

import 'dart:convert';
import 'dart:io';

/// Gestiona el registro de archivos ya importados via SHA-256.
/// Persiste en metadata/imported_hashes.json para evitar re-importaciones.
class HashService {
  final Directory _metaDir;
  final File _file;
  final Set<String> _hashes = {};

  HashService({String? basePath})
      : _metaDir = Directory(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata'),
        _file = File(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata${Platform.pathSeparator}imported_hashes.json');

  /// Crea carpeta y archivo si no existen, y carga hashes en memoria.
  Future<void> init() async {
    if (!_metaDir.existsSync()) {
      _metaDir.createSync(recursive: true);
    }
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode([]));
    }
    final content = _file.readAsStringSync();
    final List<dynamic> list = jsonDecode(content);
    _hashes.addAll(list.cast<String>());
  }

  /// Indica si ya se procesó ese hash
  bool isProcessed(String hash) => _hashes.contains(hash);

  /// Registra un hash nuevo en memoria
  void add(String hash) => _hashes.add(hash);

  /// Persiste el conjunto actual de hashes en disco
  Future<void> persist() async {
    await _file.writeAsString(jsonEncode(_hashes.toList()));
  }
}
