import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/note_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/backup_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _export(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await BackupService().exportAll();
      await Share.shareXFiles([XFile(path)], text: 'Backup Catatanku');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Gagal export: $e')));
    }
  }

  Future<void> _import(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final np = context.read<NoteProvider>();
    final result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;

    final merge = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mode Import'),
        content: const Text('Gabung dengan data lama, atau ganti semua?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Ganti')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Gabung')),
        ],
      ),
    );
    if (merge == null) return;

    try {
      final count = await BackupService()
          .importFromFile(result.files.single.path!, merge: merge);
      await np.load();
      messenger.showSnackBar(SnackBar(content: Text('$count catatan di-import')));
    } catch (e) {
      messenger.showSnackBar(const SnackBar(content: Text('Gagal import: file tidak valid')));
    }
  }

  Future<void> _purge(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final np = context.read<NoteProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bersihkan Sampah Lama?'),
        content: const Text('Hapus permanen catatan yang ada di sampah lebih dari 30 hari.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Bersihkan')),
        ],
      ),
    );
    if (ok == true) {
      await np.purgeOldTrash(days: 30);
      messenger.showSnackBar(const SnackBar(content: Text('Sampah lama dibersihkan')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        children: [
          const _Section('Tampilan'),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Mode Tema'),
            subtitle: Text(switch (theme.mode) {
              ThemeMode.system => 'Ikuti Sistem',
              ThemeMode.light => 'Terang',
              ThemeMode.dark => 'Gelap',
            }),
            onTap: () => _pickMode(context, theme),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: const Text('Warna Tema'),
            trailing: CircleAvatar(radius: 12, backgroundColor: theme.seed),
            onTap: () => _pickColor(context, theme),
          ),
          const Divider(),
          const _Section('Data'),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Export Backup'),
            subtitle: const Text('Simpan semua data ke JSON'),
            onTap: () => _export(context),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Import Backup'),
            subtitle: const Text('Gabung atau ganti data'),
            onTap: () => _import(context),
          ),
          ListTile(
            leading: const Icon(Icons.auto_delete_outlined),
            title: const Text('Bersihkan Sampah Lama'),
            subtitle: const Text('Hapus item di sampah > 30 hari'),
            onTap: () => _purge(context),
          ),
          const Divider(),
          const _Section('Tentang'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Catatanku'),
            subtitle: Text('Versi 2.0.0'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMode(BuildContext context, ThemeProvider p) async {
    final m = await showModalBottomSheet<ThemeMode>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.brightness_auto),
                title: const Text('Ikuti Sistem'),
                onTap: () => Navigator.pop(ctx, ThemeMode.system)),
            ListTile(
                leading: const Icon(Icons.light_mode),
                title: const Text('Terang'),
                onTap: () => Navigator.pop(ctx, ThemeMode.light)),
            ListTile(
                leading: const Icon(Icons.dark_mode),
                title: const Text('Gelap'),
                onTap: () => Navigator.pop(ctx, ThemeMode.dark)),
          ],
        ),
      ),
    );
    if (m != null) await p.setMode(m);
  }

  Future<void> _pickColor(BuildContext context, ThemeProvider p) async {
    final colors = <Color>[
      const Color(0xFF6750A4),
      const Color(0xFF00695C),
      const Color(0xFFC62828),
      const Color(0xFFEF6C00),
      const Color(0xFF1565C0),
      const Color(0xFF6A1B9A),
    ];
    final c = await showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Warna Tema'),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: colors
              .map((color) => GestureDetector(
                    onTap: () => Navigator.pop(ctx, color),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black26),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (c != null) await p.setSeed(c);
  }
}

class _Section extends StatelessWidget {
  final String text;
  const _Section(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary)),
      );
}
