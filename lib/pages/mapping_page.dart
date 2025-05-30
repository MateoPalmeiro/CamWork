// lib/pages/mapping_page.dart

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/mapping_service.dart';

/// Pantalla para ver/editar/borrar e importar mappings de EXIF Model → Folder
class MappingPage extends StatefulWidget {
  final MappingService mappingService;
  const MappingPage({Key? key, required this.mappingService})
      : super(key: key);

  @override
  _MappingPageState createState() => _MappingPageState();
}

class _MappingPageState extends State<MappingPage> {
  late List<MapEntry<String, String>> _list;

  @override
  void initState() {
    super.initState();
    widget.mappingService.init().then((_) {
      setState(() => _list = widget.mappingService.getAll());
    });
  }

  void _refresh() => setState(() => _list = widget.mappingService.getAll());

  Future<void> _editEntry(String model, String currentFolder) async {
    final controller = TextEditingController(text: currentFolder);
    final newFolder = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Editar carpeta para "$model"'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('Guardar')),
        ],
      ),
    );
    if (newFolder != null && newFolder.trim().isNotEmpty) {
      await widget.mappingService.update(model, newFolder.trim());
      _refresh();
    }
  }

  Future<void> _importMappings() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Importar mappings'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'ModelA:FolderA, ModelB:FolderB,…'),
          maxLines: null,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: Text('Importar')),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      await widget.mappingService.importFromText(text);
      _refresh();
    }
  }

  Future<void> _importCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (result != null && result.files.single.path != null) {
      try {
        await widget.mappingService.importFromCsv(result.files.single.path!);
        _refresh();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importando CSV: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Model–Folder Mappings'),
        actions: [
          IconButton(
            icon: Icon(Icons.upload_file),
            tooltip: 'Importar CSV',
            onPressed: _importCsv,
          ),
          IconButton(
            icon: Icon(Icons.file_upload),
            tooltip: 'Importar mappings manual',
            onPressed: _importMappings,
          ),
        ],
      ),
      body: _list.isEmpty
          ? Center(child: Text('No hay mappings configurados'))
          : ListView.builder(
              itemCount: _list.length,
              itemBuilder: (_, i) {
                final entry = _list[i];
                return ListTile(
                  title: Text(entry.key),
                  subtitle: Text(entry.value),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        tooltip: 'Editar',
                        onPressed: () => _editEntry(entry.key, entry.value),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        tooltip: 'Borrar',
                        onPressed: () async {
                          await widget.mappingService.delete(entry.key);
                          _refresh();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
