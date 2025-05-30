// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import 'import_photos_page.dart';
import 'search_duplicates_page.dart';
import 'separate_raw_page.dart';
import 'copy_private_page.dart';
import 'stats_page.dart';

/// HomePage displays the main menu of CamWork modules.
/// It lists each feature with an icon and navigates to its page on tap.
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  // Define the available modules in the home menu.
  static const List<_Module> _modules = <_Module>[
    _Module(
      title: 'Import Photos',
      icon: Icons.import_export,
      page: ImportPhotosPage(),
    ),
    _Module(
      title: 'Search Duplicates',
      icon: Icons.search,
      page: SearchDuplicatesPage(),
    ),
    _Module(
      title: 'Separate RAW',
      icon: Icons.photo_camera_back,
      page: SeparateRawPage(),
    ),
    _Module(
      title: 'Copy Private',
      icon: Icons.folder_copy,
      page: CopyPrivatePage(),
    ),
    _Module(
      title: 'Statistics',
      icon: Icons.bar_chart,
      page: StatsPage(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CamWork'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: _modules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final module = _modules[index];
          return ListTile(
            leading: Icon(module.icon),
            title: Text(module.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => module.page),
              );
            },
          );
        },
      ),
    );
  }
}

/// Private class representing a menu module.
class _Module {
  final String title;
  final IconData icon;
  final Widget page;

  const _Module({
    required this.title,
    required this.icon,
    required this.page,
  });
}
