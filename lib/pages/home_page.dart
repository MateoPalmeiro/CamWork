// lib/pages/home_page.dart

import 'package:flutter/material.dart';
import '../services/logging_service.dart';
import 'import_photos_page.dart';
import 'search_duplicates_page.dart';
import 'separate_raw_page.dart';
import 'copy_private_page.dart';
import 'stats_page.dart';
import 'settings_page.dart';
import 'about_page.dart';

class HomePage extends StatelessWidget {
  final LoggingService logger;

  const HomePage({Key? key, required this.logger}) : super(key: key);

  List<_Module> get _modules => [
        _Module(
          title: 'Import Photos',
          icon: Icons.import_export,
          page: ImportPhotosPage(logger: logger),
        ),
        _Module(
          title: 'Search Duplicates',
          icon: Icons.find_in_page,
          page: SearchDuplicatesPage(logger: logger),
        ),
        _Module(
          title: 'Separate RAW',
          icon: Icons.photo_library,
          page: SeparateRawPage(logger: logger),
        ),
        _Module(
          title: 'Copy Private',
          icon: Icons.lock,
          page: CopyPrivatePage(logger: logger),
        ),
        _Module(
          title: 'Statistics',
          icon: Icons.bar_chart,
          page: StatsPage(logger: logger),
        ),
        _Module(
          title: 'Settings',
          icon: Icons.settings,
          page: SettingsPage(logger: logger),
        ),
        _Module(
          title: 'About',
          icon: Icons.info,
          page: AboutPage(),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CamWork')),
      body: ListView.separated(
        itemCount: _modules.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final m = _modules[index];
          return ListTile(
            leading: Icon(m.icon),
            title: Text(m.title),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => m.page)),
          );
        },
      ),
    );
  }
}

class _Module {
  final String title;
  final IconData icon;
  final Widget page;
  const _Module({required this.title, required this.icon, required this.page});
}
