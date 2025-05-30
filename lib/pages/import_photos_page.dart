// lib/pages/import_photos_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/import_service.dart';
import '../services/config_service.dart';

/// Page for importing photos: prompts user to pick a source folder each time,
/// then runs model sorting and date-based grouping with progress and logs.
class ImportPhotosPage extends StatefulWidget {
  const ImportPhotosPage({Key? key}) : super(key: key);

  @override
  _ImportPhotosPageState createState() => _ImportPhotosPageState();
}

class _ImportPhotosPageState extends State<ImportPhotosPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;

  /// Starts the import workflow:
  /// 1. Prompt user to select the source folder (every run).
  /// 2. Retrieve saved CAMERAS path.
  /// 3. Run ImportService with callbacks for logging and progress.
  Future<void> _startImport() async {
    // Always ask the user for the source folder
    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected == null) {
      setState(() => _logs.add('Import cancelled: no source folder selected.'));
      return;
    }

    setState(() {
      _isRunning = true;
      _logs
        ..clear()
        ..add('Source folder: $selected');
      _progress = 0.0;
    });

    final config = ConfigService();
    final camerasPath = await config.getCamerasPath();
    if (camerasPath == null) {
      setState(() {
        _logs.add('Error: CAMERAS path is not configured.');
        _isRunning = false;
      });
      return;
    }

    final service = ImportService(
      sourceDir: Directory(selected),
      camerasDir: Directory(camerasPath),
    );

    await service.runImport(
      onLog: (message) => setState(() => _logs.add(message)),
      onProgress: (percent) => setState(() => _progress = percent),
    );

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Photos'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Select the folder where your new photos are stored each time you import.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _startImport,
              child: Text(_isRunning ? 'Importing...' : 'Start Import'),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              LinearProgressIndicator(value: _progress)
            else
              const SizedBox(height: 4),
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
                  itemBuilder: (_, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: Text(_logs[index]),
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
