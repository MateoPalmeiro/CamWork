// lib/pages/stats_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/config_service.dart';

/// Page for generating statistics and charts for the media collection.
/// This feature is experimental and may be unreliable.
class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;

  /// Starts the statistics generation workflow:
  /// 1. Retrieve saved CAMERAS path
  /// 2. Run StatsService with callbacks for logging and progress
  Future<void> _startStatistics() async {
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

    final service = StatsService(Directory(camerasPath));
    await service.generateStatistics(
      onLog: (message) => setState(() => _logs.add(message)),
      onProgress: (percent) => setState(() => _progress = percent),
    );

    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'This experimental feature analyzes your collection and '
              'generates charts and a PDF report.',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isRunning ? null : _startStatistics,
              child: Text(_isRunning ? 'Generating...' : 'Generate Statistics'),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              LinearProgressIndicator(value: _progress)
            else
              const SizedBox(height: 4),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Logs:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
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
