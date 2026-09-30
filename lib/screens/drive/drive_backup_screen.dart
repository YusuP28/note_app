import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../providers/note_provider.dart';
import '../../services/backup_service.dart';
import '../../services/google_drive_service.dart';

class DriveBackupScreen extends StatefulWidget {
  const DriveBackupScreen({super.key});

  @override
  State<DriveBackupScreen> createState() => _DriveBackupScreenState();
}

class _DriveBackupScreenState extends State<DriveBackupScreen> {
  final _drive = GoogleDriveService();
  bool _busy = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _drive.signInSilently().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _signIn() async {
    setState(() { _busy = true; _status = 'Login...'; });
    try {
      final acc = await _drive.signIn();
      if (acc == null) {
        _show('Login dibatalkan');
      } else {
        _show('Login OK: ${acc.email}');
      }
    } catch (e) {
      _show('Login gagal: $e');
    } finally {
      if (mounted) setState(() { _busy = false; _status = ''; });
    }
  }

  Future<void> _signOut() async {
    await _drive.signOut();
    if (mounted) setState(() {});
    _show('Logout OK');
  }

  Future<void> _backup() async {
    setState(() { _busy = true; _status = 'Menyiapkan backup...'; });
    try {
      // Export semua data
      final path = await BackupService().exportAll();
      final json = await _readFile(path);

      setState(() => _status = 'Upload ke Drive...');
      final fileName = 'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final id = await _drive.uploadBackup(
        fileName: fileName,
        jsonContent: json,
      );

      _show('Backup OK: ${id?.substring(0, 8)}...');
    } catch (e) {
      _show('Backup gagal: $e');
    } finally {
      if (mounted) setState(() { _busy = false; _status = ''; });
    }
  }

  Future<void> _restore() async {
    // List semua backup
    setState(() { _busy = true; _status = 'Ambil daftar backup...'; });
    try {
      final list = await _drive.listBackups();
      if (list.isEmpty) {
        _show('Belum ada backup di Drive');
        return;
      }

      if (!mounted) return;
      final picked = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        builder: (ctx) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Pilih Backup',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const Divider(height: 1),
              ...list.map((item) => ListTile(
                    leading: const Icon(Icons.cloud_download_outlined),
                    title: Text(item['name'] ?? 'unknown',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item['modified'] ?? '',
                        style: const TextStyle(fontSize: 11)),
                    onTap: () => Navigator.pop(ctx, item),
                  )),
            ],
          ),
        ),
      );
      if (picked == null) return;

      setState(() => _status = 'Download dari Drive...');
      final content = await _drive.downloadBackup(
        fileName: picked['name'] as String,
      );
      if (content == null) {
        _show('File tidak ditemukan');
        return;
      }

      // Tulis ke temp file
      setState(() => _status = 'Restore data...');
      final tmpPath = await BackupService().writeTempJson(content);
      final count = await BackupService().importFromFile(tmpPath, merge: false);

      if (mounted) {
        await context.read<NoteProvider>().load();
      }
      _show('Restore OK: $count catatan');
    } catch (e) {
      _show('Restore gagal: $e');
    } finally {
      if (mounted) setState(() { _busy = false; _status = ''; });
    }
  }

  Future<String> _readFile(String path) async {
    return await File(path).readAsString();
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _drive.currentUser;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Google Drive Backup')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status akun
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                backgroundImage: user?.photoUrl != null
                    ? NetworkImage(user!.photoUrl!)
                    : null,
                child: user == null
                    ? Icon(Icons.person_outline, color: scheme.onPrimaryContainer)
                    : null,
              ),
              title: Text(user?.displayName ?? 'Belum login'),
              subtitle: Text(user?.email ?? 'Tap untuk login Google'),
              trailing: user == null
                  ? FilledButton(onPressed: _busy ? null : _signIn, child: const Text('Login'))
                  : IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: _busy ? null : _signOut,
                    ),
            ),
          ),
          const SizedBox(height: 16),

          if (_status.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(_status, style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tombol backup
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_upload_outlined),
              title: const Text('Backup ke Drive'),
              subtitle: const Text('Upload semua catatan (notes + notebooks + tags)'),
              enabled: user != null && !_busy,
              onTap: (user == null || _busy) ? null : _backup,
            ),
          ),

          // Tombol restore
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: const Text('Restore dari Drive'),
              subtitle: const Text('Download backup + replace semua data'),
              enabled: user != null && !_busy,
              onTap: (user == null || _busy) ? null : _restore,
            ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Catatan: backup disimpan di folder tersembunyi Google Drive '
              '(appDataFolder). Tidak terlihat di Drive app, hanya bisa '
              'diakses oleh Catatanku.',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
