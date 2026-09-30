import 'package:flutter/foundation.dart';

import '../providers/settings_provider.dart';
import 'backup_service.dart';
import 'google_drive_service.dart';

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

    // Cek login Google
    final drive = GoogleDriveService();
    var user = drive.currentUser;
    user ??= await drive.signInSilently();
    if (user == null) {
      debugPrint('AutoBackup: belum login Google');
      return false;
    }

    debugPrint('AutoBackup: mulai backup untuk ${user.email}');
    try {
      // Export
      final path = await BackupService().exportAll();
      final json = await BackupService().readFile(path);

      // Upload
      final fileName =
          'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      await drive.uploadBackup(fileName: fileName, jsonContent: json);
      await drive.cleanupOldBackups(keepLast: 5);

      // Update timestamp
      await settings.setLastAutoBackup(DateTime.now());
      debugPrint('AutoBackup: SUCCESS');
      return true;
    } catch (e) {
      debugPrint('AutoBackup: FAILED — $e');
      return false;
    }
  }
}
