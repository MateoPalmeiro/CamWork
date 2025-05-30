// lib/services/mapping_service.dart

import 'dart:convert';
import 'dart:io';

/// Gestiona el archivo metadata/model_mapping.json con { EXIFModel: FolderName }.
class MappingService {
  final Directory _metaDir;
  final File _file;
  Map<String, String> _mappings = {};

  MappingService({String? basePath})
      : _metaDir = Directory(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata'),
        _file = File(
            '${basePath ?? Directory.current.path}${Platform.pathSeparator}metadata${Platform.pathSeparator}model_mapping.json');

  Future<void> init() async {
    if (!_metaDir.existsSync()) _metaDir.createSync(recursive: true);
    if (!_file.existsSync()) {
      _file.createSync(recursive: true);
      _file.writeAsStringSync(jsonEncode({}));
    }
    final content = _file.readAsStringSync();
    _mappings = Map<String, String>.from(jsonDecode(content));
  }

  List<MapEntry<String, String>> getAll() => _mappings.entries.toList();
  String? getFolderForModel(String model) => _mappings[model];
  Future<void> update(String model, String folder) async {
    _mappings[model] = folder;
    await _file.writeAsString(jsonEncode(_mappings));
  }
  Future<void> setMapping(String model, String folder) => update(model, folder);
  Future<void> delete(String model) async {
    _mappings.remove(model);
    await _file.writeAsString(jsonEncode(_mappings));
  }

  Future<void> importFromText(String text) async {
    final pairs = text.split(',');
    for (var p in pairs) {
      final parts = p.split(':');
      if (parts.length == 2) {
        final model = parts[0].trim(), folder = parts[1].trim();
        if (model.isNotEmpty && folder.isNotEmpty) _mappings[model] = folder;
      }
    }
    await _file.writeAsString(jsonEncode(_mappings));
  }

  /// Importa un CSV con líneas "model,folder"
  Future<void> importFromCsv(String csvPath) async {
    final file = File(csvPath);
    if (!file.existsSync()) throw Exception('CSV no encontrado: $csvPath');
    final lines = file.readAsLinesSync();
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length >= 2) {
        final model = parts[0].trim(), folder = parts[1].trim();
        if (model.isNotEmpty && folder.isNotEmpty) _mappings[model] = folder;
      }
    }
    await _file.writeAsString(jsonEncode(_mappings));
  }
}
