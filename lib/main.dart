// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'services/installer_service.dart';
import 'services/config_service.dart';
import 'services/logging_service.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(AppLauncher(args: args));
}

class AppLauncher extends StatelessWidget {
  final List<String> args;
  const AppLauncher({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mode = args.contains('--silent')
        ? InstallMode.silent
        : InstallMode.interactive;
    final installer = InstallerService(mode: mode);

    return MaterialApp(
      title: 'CamWork Launcher',
      home: Builder(
        builder: (ctx) {
          // Mientras comprobamos dependencias, mostramos un spinner
          if (mode == InstallMode.silent) {
            installer.handleSilent().then((_) {
              _initializeAndRun(ctx);
            });
          } else {
            installer.handleInteractive(ctx).then((_) {
              _initializeAndRun(ctx);
            });
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Future<void> _initializeAndRun(BuildContext ctx) async {
    // 1) Logging
    final logger = LoggingService(basePath: Directory.current.path);
    await logger.init();
    logger.logToFile('Application started');

    // 2) Config
    final config = ConfigService();
    final root = await config.getRootPath();

    // 3) Navegar a la app principal
    Navigator.of(ctx).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CamWorkApp(
          logger: logger,
          initialRootPath: root,
        ),
      ),
    );
  }
}

class CamWorkApp extends StatelessWidget {
  final LoggingService logger;
  final String? initialRootPath;

  const CamWorkApp({
    Key? key,
    required this.logger,
    this.initialRootPath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialRootPath == null
          ? SettingsPage(logger: logger)
          : HomePage(logger: logger),
      routes: {
        '/': (_) => HomePage(logger: logger),
      },
    );
  }
}
