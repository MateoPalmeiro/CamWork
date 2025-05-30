// lib/pages/separate_raw_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/raw_service.dart';
import '../services/config_service.dart';

/// Page for grouping RAW files (`.cr2`, `.arw`) into `RAW/` subfolders
/// under each thematic and sub-thematic folder.
class SeparateRawPage extends StatefulWidget {
  const SeparateRawPage({Key? key}) : super(key: key);

  @override
  _SeparateRawPageState createState() => _SeparateRawPageState();
}

class _SeparateRawPageState extends State<SeparateRawPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;

  /// Starts the RAW separation workflow:
  /// 1. Retrieve saved CAMERAS path
  /// 2. Run RawService with callbacks for logging and progress
  Future<void> _startRawSeparation() async {
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

    final service = RawService(Directory(camerasPath));
    await service.separateRaw(
      onLog: (message) => setState(() => _logs.add(message)),
      onProgress: (percent) => setState(() => _progress = percent),
    );

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Separate RAW'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This will scan each thematic and sub-thematic folder '
              'and move RAW files into a `RAW/` subfolder.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _startRawSeparation,
              child: Text(_isRunning ? 'Processing...' : 'Start Separation'),
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
