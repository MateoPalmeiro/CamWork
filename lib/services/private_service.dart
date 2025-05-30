// lib/services/private_service.dart

import 'dart:io';
import 'package:path/path.dart' as p;

/// Service to copy folders marked with “(X)” into CAMERAS/PRIVATE/,
/// preserving structure and avoiding overwrites.
class PrivateService {
  final Directory camerasDir;

  PrivateService(this.camerasDir);

  /// Copies any directory whose name contains “(X)”.
  Future<void> copyMarkedFolders({
    required void Function(String) onLog,
    required void Function(double) onProgress,
  }) async {
    // Gather all marked directories
    final marked = camerasDir
        .listSync(recursive: true)
        .whereType<Directory>()
        .where((d) => p.basename(d.path).contains('(X)'))
        .toList();

    final destRoot = Directory(p.join(camerasDir.path, 'PRIVATE'));
    if (!destRoot.existsSync()) destRoot.createSync();
    onLog('PRIVATE root: ${destRoot.path}');

    final total = marked.length;
    var done = 0;

    for (final dir in marked) {
      // Compute relative path under CAMERAS/
      final rel = p.relative(dir.path, from: camerasDir.path);
      final dest = Directory(p.join(destRoot.path, rel));

      if (dest.existsSync()) {
        onLog('Skipping existing: ${dest.path}');
      } else {
        try {
          _copyDirectory(dir, dest);
          onLog('Copied: ${dir.path} → ${dest.path}');
        } catch (e) {
          onLog('Error copying ${dir.path}: $e');
        }
      }
      done++;
      onProgress(done / total);
    }

    onLog('Private copy complete.');
  }

  /// Recursively copies [src] to [dest].
  void _copyDirectory(Directory src, Directory dest) {
    dest.createSync(recursive: true);
    for (final entity in src.listSync()) {
      final name = p.basename(entity.path);
      if (entity is Directory) {
        _copyDirectory(entity, Directory(p.join(dest.path, name)));
      } else if (entity is File) {
        entity.copySync(p.join(dest.path, name));
      }
    }
  }
}
