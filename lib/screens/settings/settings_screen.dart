import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../providers/settings_provider.dart';
import '../../services/alarm_service.dart';
import '../../services/image_attachment_service.dart';
import '../drive/drive_backup_screen.dart';
import '../../utils/app_routes.dart';
import 'sections/appearance_section.dart';
import 'sections/backup_section.dart';
import 'sections/security_section.dart';
import 'sections/section_header.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      // Biarkan background global tembus di layar pengaturan.
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // ============ TAMPILAN ============
          const AppearanceSection(),

          const Divider(),

          // ============ NOTIFIKASI ============
          const SettingsSectionHeader('Notifikasi & Alarm'),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Suara Alarm'),
            subtitle: Text(
              settings.notificationSound.startsWith('sound')
                  ? 'Bawaan: ${settings.notificationSound}'
                  : 'Custom: ${settings.notificationSound.split("/").last}',
            ),
            trailing: DropdownButton<String>(
              value: ['sound1', 'sound2', 'sound3']
                      .contains(settings.notificationSound)
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
                    await settings
                        .setNotificationSound(result.files.single.path!);
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
              try {
                final ok = await AlarmService().testNow();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(ok ? 'Test alarm dipicu!' : 'Gagal.')),
                  );
                }
              } catch (e) {
                debugPrint('test alarm error: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_voice_outlined),
            title: const Text('Pengaturan Suara Notifikasi'),
            subtitle: const Text('Buka channel Android (aktifkan suara)'),
            onTap: () async {
              try {
                final ok = await AlarmService().openChannelSettings();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(ok ? 'Buka pengaturan channel' : 'Gagal')),
                  );
                }
              } catch (e) {
                debugPrint('openChannelSettings error: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.alarm_on_outlined),
            title: const Text('Izin Exact Alarm'),
            subtitle: const Text('Izinkan notif tepat waktu (Android 12+)'),
            onTap: () async {
              try {
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
              } catch (e) {
                debugPrint('canScheduleExact error: $e');
              }
            },
          ),

          const Divider(),

          // ============ GOOGLE DRIVE ============
          const SettingsSectionHeader('Google Drive'),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('Backup & Restore ke Drive'),
            subtitle: const Text('Login Google + upload/download backup'),
            onTap: () => Navigator.push(
              context,
              globalBackgroundRoute((_) => const DriveBackupScreen()),
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
            subtitle:
                const Text('Foto tidak dikompresi (butuh lebih banyak ruang)'),
            value: settings.useOriginalQuality,
            onChanged: (val) async {
              await settings.setUseOriginalQuality(val);
              ImageAttachmentService().setUseOriginal(val);
            },
          ),

          const Divider(),

          // ============ BACKUP LOKAL ============
          const BackupSection(),

          const Divider(),

          // ============ KEAMANAN ============
          const SecuritySection(),

          // ============ TENTANG ============
          const SettingsSectionHeader('Tentang'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Catatanku'),
            subtitle: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Versi tidak diketahui');
                }
                final info = snapshot.data!;
                final build =
                    info.buildNumber.isEmpty ? '' : '+${info.buildNumber}';
                return Text('Versi ${info.version}$build');
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
