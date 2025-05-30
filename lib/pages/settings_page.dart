// lib/pages/settings_page.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';
import '../services/mapping_service.dart';
import 'mapping_page.dart';
import 'home_page.dart';

/// Página de ajustes donde se configura la carpeta raíz y ahora se accede a mappings
class SettingsPage extends StatefulWidget {
  final LoggingService logger;
  const SettingsPage({Key? key, required this.logger}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ConfigService _configService = ConfigService();
  late TextEditingController _rootController;

  @override
  void initState() {
    super.initState();
    _rootController = TextEditingController();
    _loadRoot();
    _rootController.addListener(() => setState(() {}));
  }

  Future<void> _loadRoot() async {
    final root = await _configService.getRootPath();
    if (root != null) {
      _rootController.text = root;
    }
  }

  Future<void> _saveRoot() async {
    final path = _rootController.text.trim();
    if (path.isEmpty) return;
    await _configService.setRootPath(path);
    widget.logger.logToFile('Root path set to $path');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => HomePage(logger: widget.logger),
      ),
    );
  }

  bool get _hasRoot => _rootController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _rootController,
              decoration: const InputDecoration(labelText: 'Carpeta raíz'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _hasRoot ? _saveRoot : null,
              child: const Text('Guardar'),
            ),
            const Divider(height: 32),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Editar Mappings de Modelos'),
              enabled: _hasRoot,
              onTap: _hasRoot
                  ? () {
                      final svc = MappingService(basePath: Directory.current.path);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MappingPage(mappingService: svc),
                        ),
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _rootController.dispose();
    super.dispose();
  }
}
