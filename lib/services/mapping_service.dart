// lib/services/mapping_service.dart

import 'dart:convert';
import 'dart:io';

/// MappingService persists a JSON file mapping EXIF camera models
/// to user-defined folder names under metadata/model_mapping.json.
class MappingService {
  final Directory _metaDir;
  final File _mapFile;
  Map<String, String> _map = {};

  MappingService({String basePath = '.'})
      : _metaDir = Directory('$basePath/metadata'),
        _mapFile = File('$basePath/metadata/model_mapping.json') {
    if (!_metaDir.existsSync()) _metaDir.createSync(recursive: true);
    if (_mapFile.existsSync()) {
      try {
        final content = _mapFile.readAsStringSync();
        _map = Map<String, String>.from(json.decode(content));
      } catch (_) {
        _map = {};
      }
    }
  }

  /// Returns the mapped folder name, or null if none.
  String? getFolderForModel(String model) => _map[model];

  /// Sets a mapping and persists the JSON file.
  Future<void> setMapping(String model, String folderName) async {
    _map[model] = folderName;
    final jsonStr = JsonEncoder.withIndent('  ').convert(_map);
    await _mapFile.writeAsString(jsonStr);
  }

  /// Lists all known model keys.
  List<String> get knownModels => _map.keys.toList();
}
