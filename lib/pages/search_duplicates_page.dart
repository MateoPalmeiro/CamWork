// lib/pages/search_duplicates_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/duplicate_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

/// SearchDuplicatesPage escanea CAMERAS/ en busca de duplicados exactos SHA256.
class SearchDuplicatesPage extends StatefulWidget {
  final LoggingService logger;
  const SearchDuplicatesPage({Key? key, required this.logger}) : super(key: key);

  @override
  _SearchDuplicatesPageState createState() => _SearchDuplicatesPageState();
}

class _SearchDuplicatesPageState extends State<SearchDuplicatesPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;
  final _config = ConfigService();

  Future<void> _startScan() async {
    final camerasPath = await _config.getCamerasPath();
    if (camerasPath == null) {
      setState(() => _logs.add('Error: root path not configured.'));
      widget.logger.logToFile('Error: root path not configured.');
      return;
    }

    setState(() {
      _isRunning = true;
      _logs.clear();
      _progress = 0.0;
    });
    widget.logger.logToFile('Starting duplicate scan at $camerasPath');

    final service = DuplicateService(Directory(camerasPath));
    await service.findDuplicates(
      onLog: (msg) {
        setState(() => _logs.add(msg));
        widget.logger.logToFile(msg);
      },
      onProgress: (p) {
        setState(() => _progress = p);
      },
    );

    widget.logger.logToFile('Duplicate scan completed.');
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Duplicates')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startScan,
              child: Text(_isRunning ? 'Scanning...' : 'Start Scan'),
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
