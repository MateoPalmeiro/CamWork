// lib/pages/copy_private_page.dart

import 'dart:io'; // <-- Necesario para Directory
import 'package:flutter/material.dart';
import '../services/private_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

/// CopyPrivatePage copia carpetas marcadas con "(X)" a CAMERAS/PRIVATE.
class CopyPrivatePage extends StatefulWidget {
  final LoggingService logger;
  const CopyPrivatePage({Key? key, required this.logger}) : super(key: key);

  @override
  _CopyPrivatePageState createState() => _CopyPrivatePageState();
}

class _CopyPrivatePageState extends State<CopyPrivatePage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;
  final _config = ConfigService();

  Future<void> _startCopyPrivate() async {
    final camerasPath = await _config.getCamerasPath();
    if (camerasPath == null) {
      const err = 'Error: root path not configured.';
      setState(() => _logs.add(err));
      widget.logger.logToFile(err);
      return;
    }

    setState(() {
      _isRunning = true;
      _logs
        ..clear()
        ..add('Starting PRIVATE copy...');
      _progress = 0.0;
    });
    widget.logger.logToFile('Starting PRIVATE copy at $camerasPath');

    final service = PrivateService(Directory(camerasPath));
    await service.copyMarkedFolders( // <-- método correcto
      onLog: (msg) {
        setState(() => _logs.add(msg));
        widget.logger.logToFile(msg);
      },
      onProgress: (p) {
        setState(() => _progress = p);
      },
    );

    widget.logger.logToFile('PRIVATE copy completed.');
    setState(() {
      _logs.add('PRIVATE copy completed.');
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Copy Private')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startCopyPrivate,
              child: Text(_isRunning ? 'Copying...' : 'Start Copy Private'),
            ),
            const SizedBox(height: 16),
            if (_isRunning) LinearProgressIndicator(value: _progress),
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
