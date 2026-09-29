import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/theme_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/backup_service.dart';
import '../../services/alarm_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Tampilan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Mode Gelap'),
            value: themeProvider.isDark,
            onChanged: (val) => themeProvider.setMode(
              val ? ThemeMode.dark : ThemeMode.light,
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Notifikasi & Alarm',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text('Suara Alarm/Notifikasi'),
            subtitle: Text(settings.notificationSound),
            trailing: DropdownButton<String>(
              value: ['sound1', 'sound2', 'sound3']
                      .contains(settings.notificationSound)
                  ? settings.notificationSound
                  : 'custom',
              items: const [
                DropdownMenuItem(
                  value: 'sound1',
                  child: Text('Sound 1'),
                ),
                DropdownMenuItem(
                  value: 'sound2',
                  child: Text('Sound 2'),
                ),
                DropdownMenuItem(
                  value: 'sound3',
                  child: Text('Sound 3'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Pilih File...'),
                ),
              ],
              onChanged: (val) async {
                if (val == 'custom') {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                  );
                  if (result != null && result.files.single.path != null) {
                    await settings.setNotificationSound(
                      result.files.single.path!,
                    );
                  }
                } else if (val != null) {
                  await settings.setNotificationSound(val);
                }
              },
            ),
          ),
          ListTile(
            title: const Text('Test Alarm Sekarang'),
            subtitle: const Text('Uji notifikasi full-screen'),
            trailing: const Icon(Icons.alarm),
            onTap: () async {
              final ok = await AlarmService().testNow();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Test alarm dipicu!'
                          : 'Test alarm gagal dipicu.',
                    ),
                  ),
                );
              }
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Backup & Pemulihan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            title: const Text('Backup Data (JSON)'),
            leading: const Icon(Icons.backup),
            onTap: () async {
              try {
                final path = await BackupService().exportAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Backup tersimpan di $path'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal backup: $e'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
