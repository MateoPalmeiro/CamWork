// lib/pages/stats_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/stats_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

/// StatsPage genera estadísticas globales (experimental).
class StatsPage extends StatefulWidget {
  final LoggingService logger;
  const StatsPage({Key? key, required this.logger}) : super(key: key);

  @override
  _StatsPageState createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final List<String> _logs = [];
  double _progress = 0.0;
  bool _isRunning = false;
  final _config = ConfigService();

  Future<void> _startStats() async {
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
    widget.logger.logToFile('Starting statistics generation at $camerasPath');

    final service = StatsService(Directory(camerasPath));
    await service.generateStatistics(
      onLog: (msg) {
        setState(() => _logs.add(msg));
        widget.logger.logToFile(msg);
      },
      onProgress: (p) {
        setState(() => _progress = p);
      },
    );

    widget.logger.logToFile('Statistics generation completed.');
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics (Experimental)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isRunning ? null : _startStats,
              child: Text(_isRunning ? 'Running...' : 'Run Statistics'),
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
