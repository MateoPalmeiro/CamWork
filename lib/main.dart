// lib/main.dart

import 'package:flutter/material.dart';
import 'pages/home_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized for any asynchronous setup
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CamWorkApp());
}

/// CamWorkApp is the root widget of the application.
/// It configures the Material theme and sets the HomePage as the initial screen.
class CamWorkApp extends StatelessWidget {
  const CamWorkApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CamWork',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}
