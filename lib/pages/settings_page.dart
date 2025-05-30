// lib/pages/settings_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/config_service.dart';

/// SettingsPage allows the user to select and persist the application's root path.
/// Upon saving, it creates the subfolders: CAMERAS/, logs/, pdf/, metadata/
class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _rootPath;
  final _config = ConfigService();

  @override
  void initState() {
    super.initState();
    _loadRootPath();
  }

  Future<void> _loadRootPath() async {
    final path = await _config.getRootPath();
    setState(() => _rootPath = path);
  }

  Future<void> _pickRootFolder() async {
    final selected = await FilePicker.platform.getDirectoryPath();
    if (selected != null) {
      setState(() => _rootPath = selected);
    }
  }

  Future<void> _saveRootPath() async {
    if (_rootPath == null) return;
    await _config.setRootPath(_rootPath!);
    // create subfolders
    for (final dir in ['CAMERAS', 'logs', 'pdf', 'metadata']) {
      final folder = Directory('$_rootPath/$dir');
      if (!folder.existsSync()) folder.createSync(recursive: true);
    }
    // navigate to Home
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select the root folder where CamWork will store its data.',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open),
              label: Text(
                _rootPath == null
                  ? 'Choose Root Folder'
                  : _rootPath!,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: _pickRootFolder,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_rootPath == null) ? null : _saveRootPath,
              child: const Text('Save and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
