// lib/pages/about_page.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// AboutPage displays app metadata: name, version, author and repository link.
class AboutPage extends StatefulWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appName = 'CamWork';
  String _version = '1.0.0';
  String _buildNumber = '';
  
  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appName = info.appName;
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$_appName v$_version ($_buildNumber)', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            const Text('Author: Your Name'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => launchUrlString('https://github.com/yourrepo'),
              child: const Text(
                'https://github.com/yourrepo',
                style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
            const Spacer(),
            const Text('Professional Photo Processing Suite'),
          ],
        ),
      ),
    );
  }
}
