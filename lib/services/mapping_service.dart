// lib/services/mapping_service.dart

import 'dart:convert';
import 'dart:io';

/// Gestiona el archivo metadata/model_mapping.json con { EXIFModel: FolderName }.
class MappingService {
  final Directory _metaDir;
  final File _file;
  Map<String, String> _mappings = {};

  /// [basePath] opcional para indicar dónde está la carpeta 'metadata'.
  MappingService({String? basePath})
      : _metaDir = Directory(
          '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata',
        ),
        _file = File(
          '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata'
          '${Platform.pathSeparator}model_mapping.json',
        );

  /// Crea metadata/ y el JSON si falta, luego carga los mappings.
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

  /// Todos los mappings actuales.
  List<MapEntry<String, String>> getAll() => _mappings.entries.toList();

  /// Carpeta mapeada o null si no existe.
  String? getFolderForModel(String model) => _mappings[model];

  /// Crea o actualiza un mapping.
  Future<void> update(String model, String folder) async {
    _mappings[model] = folder;
    await _file.writeAsString(jsonEncode(_mappings));
  }

  /// Alias para el import desde ImportPhotosPage.
  Future<void> setMapping(String model, String folder) => update(model, folder);

  /// Elimina un mapping.
  Future<void> delete(String model) async {
    _mappings.remove(model);
    await _file.writeAsString(jsonEncode(_mappings));
  }

  /// Importa mappings de texto "M1:F1, M2:F2, …".
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

  /// Importa un CSV donde cada línea es "model,folder".
  Future<void> importFromCsv(String csvPath) async {
    final file = File(csvPath);
    if (!file.existsSync()) {
      throw Exception('CSV no encontrado: $csvPath');
    }
    final lines = file.readAsLinesSync();
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length >= 2) {
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
