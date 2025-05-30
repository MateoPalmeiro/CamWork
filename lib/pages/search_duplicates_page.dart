// lib/pages/search_duplicates_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/duplicate_service.dart';
import '../services/config_service.dart';

/// Page for searching exact duplicates using SHA256 within each camera model.
/// Shows progress and logs of the duplicate detection workflow.
class SearchDuplicatesPage extends StatefulWidget {
  const SearchDuplicatesPage({Key? key}) : super(key: key);

  @override
  _SearchDuplicatesPageState createState() => _SearchDuplicatesPageState();
}

class _SearchDuplicatesPageState extends State<SearchDuplicatesPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;

  /// Starts the duplicate search workflow:
  /// 1. Retrieve saved CAMERAS path
  /// 2. Run DuplicateService with callbacks for logging and progress
  Future<void> _startDuplicateSearch() async {
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

    final service = DuplicateService(Directory(camerasPath));
    await service.findDuplicates(
      onLog: (message) {
        setState(() => _logs.add(message));
      },
      onProgress: (percent) {
        setState(() => _progress = percent);
      },
    );

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Duplicates'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This will scan each camera model folder for files with matching '
              'name and extension, then compute SHA256 to identify true duplicates.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _startDuplicateSearch,
              child: Text(_isRunning ? 'Scanning...' : 'Start Scan'),
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
