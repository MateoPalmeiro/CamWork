// lib/pages/import_photos_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/import_service.dart';
import '../services/hash_service.dart';
import '../services/mapping_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

class ImportPhotosPage extends StatefulWidget {
  final LoggingService logger;
  const ImportPhotosPage({Key? key, required this.logger}) : super(key: key);

  @override
  _ImportPhotosPageState createState() => _ImportPhotosPageState();
}

class _ImportPhotosPageState extends State<ImportPhotosPage> {
  final List<String> _logs = [];
  final List<String> _errors = [];
  double _progress = 0.0;
  bool _isRunning = false;
  bool _dryRun = false;

  late final MappingService _mappingService;
  late final HashService _hashService;
  late final ConfigService _configService;

  @override
  void initState() {
    super.initState();
    _mappingService = MappingService(basePath: Directory.current.path);
    _hashService = HashService(basePath: Directory.current.path);
    _configService = ConfigService();
  }

  Future<void> _startImport() async {
    final sourcePath = await FilePicker.platform.getDirectoryPath();
    if (sourcePath == null) {
      _appendLog('Import cancelled: no source folder selected.');
      return;
    }

    final camerasPath = await _configService.getCamerasPath();
    if (camerasPath == null) {
      _appendLog('Error: root path not configured.');
      return;
    }

    setState(() {
      _isRunning = true;
      _logs.clear();
      _errors.clear();
      _appendLog('Dry-run: $_dryRun');
      _appendLog('Source: $sourcePath');
      _progress = 0.0;
    });

    final service = ImportService(
      sourceDir: Directory(sourcePath),
      camerasDir: Directory(camerasPath),
      mappingService: _mappingService,
      hashService: _hashService,
      configService: _configService,
      loggingService: widget.logger,
    );

    await service.runImport(
      askFolderForModel: _askFolderForModel,
      onLog: _appendLog,
      onProgress: (p) => setState(() => _progress = p),
      onError: (err) => _errors.add(err),
      dryRun: _dryRun,
    );

    setState(() => _isRunning = false);

    if (_errors.isNotEmpty) {
      final retry = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Se encontraron ${_errors.length} errores'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: _errors.map((e) => Text('- $e')).toList(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cerrar')),
            TextButton(onPressed: () => Navigator.pop(context, true),  child: Text('Reintentar')),
          ],
        ),
      );
      if (retry == true) _startImport();
    }
  }

  Future<String> _askFolderForModel(String model) async {
    await _mappingService.init();
    final mapped = _mappingService.getFolderForModel(model);
    if (mapped != null) return mapped;

    final camerasPath = await _configService.getCamerasPath();
    if (camerasPath == null) {
      final folder = model;
      await _mappingService.setMapping(model, folder);
      return folder;
    }

    final existing = Directory(camerasPath)
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .toList();

    final result = await showDialog<String>(
      context: context,
      builder: (_) => _ModelFolderDialog(model: model, existing: existing),
    );

    final folder = (result != null && result.isNotEmpty) ? result : model;
    await _mappingService.setMapping(model, folder);
    return folder;
  }

  void _appendLog(String msg) {
    setState(() => _logs.add(msg));
    widget.logger.logToFile(msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Photos')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Checkbox(
                  value: _dryRun,
                  onChanged: (v) => setState(() => _dryRun = v ?? false),
                ),
                const Text('Dry-run (preview only)'),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isRunning ? null : _startImport,
                  child: Text(_isRunning ? 'Importing...' : 'Start Import'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isRunning) LinearProgressIndicator(value: _progress),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(_logs[i]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelFolderDialog extends StatefulWidget {
  final String model;
  final List<String> existing;
  const _ModelFolderDialog({Key? key, required this.model, required this.existing})
      : super(key: key);

  @override
  __ModelFolderDialogState createState() => __ModelFolderDialogState();
}

class __ModelFolderDialogState extends State<_ModelFolderDialog> {
  String? _selected;
  final _newController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Map "${widget.model}" to folder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<String>(
            value: _selected,
            hint: const Text('Select existing folder'),
            items: widget.existing
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
          ),
          const Divider(),
          TextField(
            controller: _newController,
            decoration: const InputDecoration(labelText: 'Or create new folder'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final entered = _newController.text.trim();
            final chosen = entered.isNotEmpty ? entered : _selected ?? '';
            Navigator.pop(context, chosen);
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
