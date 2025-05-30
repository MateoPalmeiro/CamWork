import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/installer_service.dart';
import 'services/config_service.dart';
import 'services/logging_service.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';

void main(List<String> args) {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(RootApp(args: args));
}

class RootApp extends StatelessWidget {
  final List<String> args;
  const RootApp({Key? key, required this.args}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamWork Launcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],
      home: AppLauncher(args: args),
    );
  }
}

class AppLauncher extends StatefulWidget {
  final List<String> args;
  const AppLauncher({Key? key, required this.args}) : super(key: key);

  @override
  State<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends State<AppLauncher> {
  bool _ready = false;
  late final LoggingService _logger;
  String? _initialRoot;

  @override
  void initState() {
    super.initState();
    _launch();
  }

  Future<void> _launch() async {
    final mode = widget.args.contains('--silent')
        ? InstallMode.silent
        : InstallMode.interactive;
    final installer = InstallerService(mode: mode);

    if (mode == InstallMode.silent) {
      await installer.handleSilent();
    } else {
      await installer.handleInteractive(context);
    }

    _logger = LoggingService(basePath: Directory.current.path);
    await _logger.init();
    _logger.logToFile('Application started');

    final config = ConfigService();
    _initialRoot = await config.getRootPath();

    if (!mounted) return;
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return CamWorkApp(
      logger: _logger,
      initialRootPath: _initialRoot,
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
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],
      home: initialRootPath == null
          ? SettingsPage(logger: logger)
          : HomePage(logger: logger),
      routes: {
        '/settings': (_) => SettingsPage(logger: logger),
        '/home': (_) => HomePage(logger: logger),
      },
    );
  }
}
