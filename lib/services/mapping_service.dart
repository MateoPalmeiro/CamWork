// lib/services/mapping_service.dart

import 'dart:convert';
import 'dart:io';

/// Gestiona el archivo metadata/model_mapping.json con { EXIFModel: FolderName }.
class MappingService {
  final Directory _metaDir;
  final File _file;
  Map<String, String> _mappings = {};

  /// Ahora recibe opcionalmente la ruta base donde está la carpeta metadata.
  MappingService({String? basePath})
      : _metaDir = Directory(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata'),
        _file = File(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata${Platform.pathSeparator}model_mapping.json');

  /// Crea la carpeta metadata/ y el archivo si no existen, luego carga los mappings.
  Future<void> init() async {
    if (!_metaDir.existsSync()) {
      _metaDir.createSync(recursive: true);
    }
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode({}));
    }
    final content = _file.readAsStringSync();
    _mappings = Map<String, String>.from(jsonDecode(content));
  }

  /// Devuelve todos los mappings como lista de entradas.
  List<MapEntry<String, String>> getAll() => _mappings.entries.toList();

  /// Recupera (o null) la carpeta mapeada para un modelo dado.
  String? getFolderForModel(String model) => _mappings[model];

  /// Crea o actualiza un mapping y lo persiste.
  Future<void> update(String model, String folder) async {
    _mappings[model] = folder;
    await _file.writeAsString(jsonEncode(_mappings));
  }

  /// Alias claro para usar en ImportPhotosPage
  Future<void> setMapping(String model, String folder) =>
      update(model, folder);

  /// Elimina un mapping por modelo y lo persiste.
  Future<void> delete(String model) async {
    _mappings.remove(model);
    await _file.writeAsString(jsonEncode(_mappings));
  }

  /// Importa múltiples mappings desde un texto "M1:F1, M2:F2, ..."
  Future<void> importFromText(String text) async {
    final pairs = text.split(',');
    for (var p in pairs) {
      final parts = p.split(':');
      if (parts.length == 2) {
        final model = parts[0].trim();
        final folder = parts[1].trim();
        if (model.isNotEmpty && folder.isNotEmpty) {
          _mappings[model] = folder;
        }
      }
    }
    await _file.writeAsString(jsonEncode(_mappings));
  }
}
