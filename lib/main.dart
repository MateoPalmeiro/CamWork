// lib/main.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'services/config_service.dart';
import 'services/logging_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar LoggingService
  final logger = LoggingService(basePath: Directory.current.path);
  await logger.init();
  logger.logToFile('Application started');

  // Comprobar si ya hay root_path configurado
  final config = ConfigService();
  final root = await config.getRootPath();

  runApp(CamWorkApp(
    logger: logger,
    initialRootPath: root,
  ));
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
      // Si no hay root_path vamos a SettingsPage, si no a HomePage
      home: initialRootPath == null
          ? SettingsPage(logger: logger)
          : HomePage(logger: logger),
      routes: {
        '/': (_) => HomePage(logger: logger),
      },
    );
  }
}
