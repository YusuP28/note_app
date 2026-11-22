import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';
import 'backup_service.dart';
import 'local_backup_service.dart';

class AutoBackupService {
  static final AutoBackupService _i = AutoBackupService._();
  factory AutoBackupService() => _i;
  AutoBackupService._();

  /// Cek + jalankan auto-backup kalau sudah waktunya.
  /// Return true kalau backup dijalankan.
  Future<bool> checkAndRun(SettingsProvider settings) async {
    if (!settings.autoBackupEnabled) {
      return false;
    }
    if (!settings.shouldAutoBackup()) {
      debugPrint('AutoBackup: belum waktunya');
      return false;
    }

    debugPrint('AutoBackup: mulai backup lokal');
    try {
      // Export ke memory (tidak meninggalkan ZIP di storage publik).
      final bytes = await BackupService().exportToBytes();

      // Simpan ke folder lokal
      final localBackup = LocalBackupService();
      final fileName =
          'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final backupDir = await localBackup._getBackupDirectory();
      final target = File('${backupDir.path}/$fileName');
      await target.writeAsBytes(bytes, flush: true);
      
      // Cleanup old backups
      await localBackup.cleanupOldBackups(keepLast: 5);

      // Update timestamp
      await settings.setLastAutoBackup(DateTime.now());
      debugPrint('AutoBackup: SUCCESS — ${target.path}');
      return true;
    } catch (e) {
      debugPrint('AutoBackup: FAILED — $e');
      return false;
    }
  }
}