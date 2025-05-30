// lib/pages/copy_private_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/private_service.dart';
import '../services/config_service.dart';

/// Page for copying folders marked with “(X)” into the PRIVATE/ directory.
/// Preserves existing content and logs all operations.
class CopyPrivatePage extends StatefulWidget {
  const CopyPrivatePage({Key? key}) : super(key: key);

  @override
  _CopyPrivatePageState createState() => _CopyPrivatePageState();
}

class _CopyPrivatePageState extends State<CopyPrivatePage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;

  /// Starts the “copy private” workflow:
  /// 1. Retrieve saved CAMERAS path
  /// 2. Run PrivateService with callbacks for logging and progress
  Future<void> _startCopyPrivate() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
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

    final service = PrivateService(Directory(camerasPath));
    await service.copyMarkedFolders(
      onLog: (message) => setState(() => _logs.add(message)),
      onProgress: (percent) => setState(() => _progress = percent),
    );

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Copy Private'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This will copy any folder whose name contains "(X)" '
              'into the PRIVATE/ directory, without overwriting existing content.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _startCopyPrivate,
              child: Text(_isRunning ? 'Copying...' : 'Start Copy'),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              LinearProgressIndicator(value: _progress)
            else
              const SizedBox(height: 4),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Logs:', style: TextStyle(fontWeight: FontWeight.bold)),
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
