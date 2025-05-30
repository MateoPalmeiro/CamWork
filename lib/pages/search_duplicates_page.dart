// lib/pages/search_duplicates_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/duplicate_service.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';

class SearchDuplicatesPage extends StatefulWidget {
  final LoggingService logger;
  const SearchDuplicatesPage({Key? key, required this.logger}) : super(key: key);

  @override
  _SearchDuplicatesPageState createState() => _SearchDuplicatesPageState();
}

class _SearchDuplicatesPageState extends State<SearchDuplicatesPage> {
  final _configService = ConfigService();
  bool _isRunning = false;
  List<List<File>> _groups = [];

  Future<void> _runSearch() async {
    final root = await _configService.getCamerasPath();
    if (root == null) {
      widget.logger.logToFile('Error: root path not configured.');
      return;
    }

    setState(() {
      _isRunning = true;
      _groups.clear();
    });

    final camerasDir = Directory(root);
    final service = DuplicateService(camerasDir);

    final groups = await service.findDuplicateGroups();
    widget.logger.logToFile('Found ${groups.length} duplicate groups.');

    setState(() {
      _groups = groups;
      _isRunning = false;
    });
  }

  Future<void> _showPreview(List<File> group, int groupIndex) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        child: StatefulBuilder(
          builder: (ctx, setDialogState) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Duplicates in Group ${groupIndex + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < group.length; i += 2)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _imageWithDelete(group, groupIndex, i, setDialogState),
                        if (i + 1 < group.length)
                          _imageWithDelete(group, groupIndex, i + 1, setDialogState),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    setState(() {}); // Refresh main list
  }

  Widget _imageWithDelete(
    List<File> group,
    int groupIndex,
    int fileIndex,
    StateSetter setDialogState,
  ) {
    final file = group[fileIndex];
    return Expanded(
      child: Column(
        children: [
          Image.file(
            file,
            width: 150,
            height: 150,
            fit: BoxFit.cover,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete this file',
            onPressed: () {
              try {
                file.deleteSync();
                widget.logger.logToFile('Deleted duplicate: ${file.path}');
                group.removeAt(fileIndex);
                if (group.length < 2) {
                  _groups.removeAt(groupIndex);
                }
                setDialogState(() {});
              } catch (e) {
                widget.logger.logToFile('Error deleting ${file.path}: $e');
              }
            },
          ),
        ],
      ),
    );
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
              onPressed: _isRunning ? null : _runSearch,
              child: Text(_isRunning ? 'Searching...' : 'Search Duplicates'),
            ),
            const SizedBox(height: 16),
            if (_isRunning)
              const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Expanded(
              child: _groups.isEmpty
                  ? const Center(child: Text('No duplicates found.'))
                  : ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (_, i) {
                        final group = _groups[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('Group ${i + 1} (${group.length} files)'),
                            subtitle: Row(
                              children: group.take(2).map((file) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Image.file(
                                    file,
                                    width: 64,
                                    height: 64,
                                    fit: BoxFit.cover,
                                  ),
                                );
                              }).toList(),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.fullscreen),
                              tooltip: 'Preview & delete',
                              onPressed: () => _showPreview(group, i),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
