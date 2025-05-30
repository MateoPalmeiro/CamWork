// lib/pages/settings_page.dart

import 'package:flutter/material.dart';
import '../services/config_service.dart';
import '../services/logging_service.dart';
import '../services/mapping_service.dart';
import 'mapping_page.dart';

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
  }

  Future<void> _loadRoot() async {
    final root = await _configService.getRootPath();
    if (root != null) {
      _rootController.text = root;
    }
  }

  Future<void> _saveRoot() async {
    final path = _rootController.text.trim();
    if (path.isNotEmpty) {
      await _configService.setRootPath(path);
      widget.logger.logToFile('Root path set to $path');
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ajustes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _rootController,
              decoration: InputDecoration(labelText: 'Carpeta raíz'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveRoot,
              child: Text('Guardar'),
            ),
            Divider(height: 32),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Editar Mappings de Modelos'),
              onTap: () {
                final svc = MappingService();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MappingPage(mappingService: svc),
                  ),
                );
              },
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
