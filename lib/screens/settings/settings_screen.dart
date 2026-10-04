import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/note_provider.dart';
import '../../services/backup_service.dart';
import '../../services/alarm_service.dart';
import '../../services/image_attachment_service.dart';
import '../drive/drive_backup_screen.dart';
import '../../themes/neumo.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: Neumo.bg(context),
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // ============ TAMPILAN ============
          _section('Tampilan'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode Gelap'),
            value: themeProvider.isDark,
            onChanged: (val) => themeProvider.setMode(
              val ? ThemeMode.dark : ThemeMode.light,
            ),
          ),

          const Divider(),

          // ============ NOTIFIKASI ============
          _section('Notifikasi & Alarm'),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Suara Alarm'),
            subtitle: Text(
              settings.notificationSound.startsWith('sound')
                  ? 'Bawaan: ${settings.notificationSound}'
                  : 'Custom: ${settings.notificationSound.split("/").last}',
            ),
            trailing: DropdownButton<String>(
              value: ['sound1', 'sound2', 'sound3'].contains(settings.notificationSound)
                  ? settings.notificationSound
                  : 'custom',
              items: const [
                DropdownMenuItem(value: 'sound1', child: Text('Sound 1')),
                DropdownMenuItem(value: 'sound2', child: Text('Sound 2')),
                DropdownMenuItem(value: 'sound3', child: Text('Sound 3')),
                DropdownMenuItem(value: 'custom', child: Text('Pilih File...')),
              ],
              onChanged: (val) async {
                if (val == 'custom') {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                  );
                  if (result != null && result.files.single.path != null) {
                    await settings.setNotificationSound(result.files.single.path!);
                  }
                } else if (val != null) {
                  await settings.setNotificationSound(val);
                }
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.alarm),
            title: const Text('Test Alarm Sekarang'),
            subtitle: const Text('Uji notifikasi full-screen + suara'),
            onTap: () async {
              final ok = await AlarmService().testNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Test alarm dipicu!' : 'Gagal.')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_voice_outlined),
            title: const Text('Pengaturan Suara Notifikasi'),
            subtitle: const Text('Buka channel Android (aktifkan suara)'),
            onTap: () async {
              final ok = await AlarmService().openChannelSettings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(ok ? 'Buka pengaturan channel' : 'Gagal')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm_on_outlined),
            title: const Text('Izin Exact Alarm'),
            subtitle: const Text('Izinkan notif tepat waktu (Android 12+)'),
            onTap: () async {
              final can = await AlarmService().canScheduleExact();
              if (can) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Izin sudah aktif')),
                  );
                }
                return;
              }
              await AlarmService().requestExactPermission();
            },
          ),

          const Divider(),

          // ============ GOOGLE DRIVE ============
          _section('Google Drive'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Backup & Restore ke Drive'),
            subtitle: const Text('Login Google + upload/download backup'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DriveBackupScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Auto-Backup Otomatis'),
            subtitle: Text(
              settings.autoBackupEnabled
                  ? 'Setiap ${settings.autoBackupDays} hari sekali'
                  : 'Nonaktif',
            ),
            trailing: DropdownButton<int>(
              value: settings.autoBackupDays,
              items: const [
                DropdownMenuItem(value: 0, child: Text('Off')),
                DropdownMenuItem(value: 1, child: Text('1 hari')),
                DropdownMenuItem(value: 2, child: Text('2 hari')),
                DropdownMenuItem(value: 3, child: Text('3 hari')),
                DropdownMenuItem(value: 4, child: Text('4 hari')),
                DropdownMenuItem(value: 5, child: Text('5 hari')),
                DropdownMenuItem(value: 6, child: Text('6 hari')),
                DropdownMenuItem(value: 7, child: Text('7 hari')),
              ],
              onChanged: (val) async {
                if (val != null) await settings.setAutoBackupDays(val);
              },
            ),
          ),
          if (settings.autoBackupEnabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                settings.lastAutoBackup == null
                    ? 'Belum pernah backup otomatis'
                    : 'Terakhir: ${settings.lastAutoBackup}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          SwitchListTile(
            secondary: const Icon(Icons.high_quality_outlined),
            title: const Text('Ukuran Foto Asli'),
            subtitle: const Text('Foto tidak dikompresi (butuh lebih banyak ruang)'),
            value: settings.useOriginalQuality,
            onChanged: (val) async {
              await settings.setUseOriginalQuality(val);
              ImageAttachmentService().setUseOriginal(val);
            },
          ),

          const Divider(),

          // ============ BACKUP LOKAL ============
          _section('Backup Lokal'),
          ListTile(
            leading: const Icon(Icons.save_outlined),
            title: const Text('Backup Data (JSON)'),
            subtitle: const Text('Simpan semua data ke file lokal'),
            onTap: () async {
              try {
                final path = await BackupService().exportAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Backup: $path')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal backup: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Restore dari File'),
            subtitle: const Text('Import backup JSON (replace)'),
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
              );
              if (result == null || result.files.single.path == null) return;
              try {
                final count = await BackupService()
                    .importFromFile(result.files.single.path!, merge: false);
                if (context.mounted) {
                  await context.read<NoteProvider>().load();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Restore: $count catatan')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal restore: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: const Text('Bersihkan Sampah Lama'),
            subtitle: const Text('Hapus item di sampah > 30 hari'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Bersihkan Sampah?'),
                  content: const Text('Hapus permanen catatan di sampah > 30 hari.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Bersihkan')),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                await context.read<NoteProvider>().purgeOldTrash(days: 30);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sampah lama dibersihkan')),
                  );
                }
              }
            },
          ),

          const Divider(),

          // ============ TENTANG ============
          _section('Tentang'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Catatanku'),
            subtitle: const Text('Versi 2.3.1'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Neumo.textSub(context),
          ),
        ),
      );
}
