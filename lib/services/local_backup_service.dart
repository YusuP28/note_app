import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'backup_service.dart';

class LocalBackupService {
  static const String _backupFolderName = 'note_app';
  static const int _maxAutoBackups = 5;

  /// Get the backup directory: /storage/emulated/0/note_app/
  Future<Directory> _getBackupDirectory() async {
    // Try external storage first (public folder)
    Directory externalDir = Directory('/storage/emulated/0/$_backupFolderName');
    
    if (await _ensureWritable(externalDir)) {
      return externalDir;
    }

    // Fallback: try requesting permission
    try {
      final status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
      if (await _ensureWritable(externalDir)) {
        return externalDir;
      }
    } catch (_) {}

    // Fallback: use app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final fallbackDir = Directory(p.join(appDir.path, _backupFolderName));
    await fallbackDir.create(recursive: true);
    return fallbackDir;
  }

  Future<bool> _ensureWritable(Directory dir) async {
    try {
      if (!await dir.exists()) await dir.create(recursive: true);
      final probe = File(p.join(dir.path, '.note_app_write_test'));
      await probe.writeAsString('ok', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Create a backup ZIP file with timestamp in /storage/emulated/0/note_app/
  /// Returns the path to the created backup file
  Future<String> backupData() async {
    final backupDir = await _getBackupDirectory();
    final fileName = 'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
    final targetPath = p.join(backupDir.path, fileName);
    
    final bytes = await BackupService().exportToBytes();
    final target = File(targetPath);
    await target.writeAsBytes(bytes, flush: true);
    return target.path;
  }

  /// Restore from a backup ZIP file
  /// Returns number of imported notes
  Future<int> restoreData(File zipFile) async {
    return BackupService().importFromFile(zipFile.path, merge: false);
  }

  /// Get list of available backup files (newest first)
  Future<List<File>> listBackups() async {
    final backupDir = await _getBackupDirectory();
    if (!await backupDir.exists()) return [];
    
    final files = await backupDir
        .list()
        .where((e) => e is File && e.path.endsWith('.zip'))
        .cast<File>()
        .toList();
    
    files.sort((a, b) => b.path.compareTo(a.path)); // Newest first
    return files;
  }

  /// Clean up old backup files, keep only the last N
  Future<int> cleanupOldBackups({int keepLast = 5}) async {
    final backupDir = await _getBackupDirectory();
    if (!await backupDir.exists()) return 0;
    
    final files = await backupDir
        .list()
        .where((e) => e is File && e.path.endsWith('.zip'))
        .cast<File>()
        .toList();
    
    files.sort((a, b) => a.path.compareTo(b.path)); // Oldest first
    
    int deleted = 0;
    while (files.length > keepLast) {
      final old = files.removeAt(0);
      try {
        await old.delete();
        deleted++;
      } catch (_) {}
    }
    return deleted;
  }

  /// Get the backup directory path for UI display
  Future<String> getBackupFolderPath() async {
    final dir = await _getBackupDirectory();
    return dir.path;
  }
}