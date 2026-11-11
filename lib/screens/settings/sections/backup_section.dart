import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:note_app_core/note_app_core.dart';
import 'package:provider/provider.dart';

import '../../../providers/note_provider.dart';
import '../../../services/backup_passphrase_service.dart';
import '../../../services/backup_service.dart';
import '../../../themes/neumo.dart';
import 'section_header.dart';

/// Section "Backup Lokal" di layar pengaturan.
///
/// Berisi passphrase backup, ekspor/impor file backup, dan pembersihan
/// sampah lama.
///
/// Teks UI, ikon, dan urutan tile sama persis dengan versi lama; yang
/// berubah hanya letak kodenya.
class BackupSection extends StatelessWidget {
  const BackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader('Backup Lokal'),
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: const Text('Passphrase Backup'),
          subtitle: const Text(
            'Kunci enkripsi file backup. Wajib untuk restore di perangkat lain.',
          ),
          onTap: () => _showPassphraseSheet(context),
        ),
        ListTile(
          leading: const Icon(Icons.save_outlined),
          title: const Text('Backup Data (ZIP)'),
          subtitle: const Text(
            'Simpan semua catatan + lampiran ke file terenkripsi',
          ),
          onTap: () async {
            try {
              final bytes = await BackupService().exportAllBytes();
              final fileName =
                  'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.nbak';
              // Storage Access Framework: user sendiri yang memilih lokasi
              // file lewat system picker. Tidak butuh izin akses storage
              // eksternal (MANAGE_EXTERNAL_STORAGE sudah dihapus).
              final saved = await FilePicker.platform.saveFile(
                dialogTitle: 'Simpan file backup',
                fileName: fileName,
                type: FileType.any,
                bytes: bytes,
              );
              if (!context.mounted) return;
              if (saved == null) return; // user membatalkan
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Backup tersimpan: $fileName')),
              );
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
          subtitle: const Text('Import backup terenkripsi / ZIP / JSON'),
          onTap: () async {
            final result = await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['nbak', 'zip', 'json'],
            );
            if (result == null || result.files.single.path == null) return;
            final path = result.files.single.path!;
            if (!context.mounted) return;

            // Minta passphrase bila file terenkripsi & passphrase lokal
            // tidak cocok (mis. backup dari perangkat lain).
            String? passphrase;
            final stored = await BackupPassphraseService().passphrase();
            if (stored == null || stored.isEmpty) {
              if (!context.mounted) return;
              passphrase = await _promptPassphrase(context);
              if (passphrase == null) return;
            }

            try {
              final count = await BackupService().importFromFile(
                path,
                merge: false,
                passphrase: passphrase,
              );
              if (!context.mounted) return;
              await context.read<NoteProvider>().load();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Restore: $count catatan')),
              );
            } on BackupDecryptException catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.message)),
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
                content:
                    const Text('Hapus permanen catatan di sampah > 30 hari.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Batal'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Bersihkan'),
                  ),
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
      ],
    );
  }

  /// Dialog input passphrase. Return null kalau user batal.
  Future<String?> _promptPassphrase(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passphrase Backup'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Passphrase',
            helperText: 'Passphrase yang dipakai saat membuat backup',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Lanjut'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  /// Sheet untuk melihat / mengganti passphrase backup.
  Future<void> _showPassphraseSheet(BuildContext context) async {
    final service = BackupPassphraseService();
    final current = await service.passphrase();

    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Passphrase Backup',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (current == null || current.isEmpty)
                const Text(
                  'Belum ada passphrase. Backup akan memakai passphrase acak '
                  'yang otomatis dibuat.',
                )
              else
                SelectableText(
                  current,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              const SizedBox(height: 8),
              Text(
                'Simpan passphrase ini di tempat aman. Backups yang terenkripsi '
                'TIDAK bisa dipulihkan tanpa passphrase yang benar - termasuk '
                'di perangkat lain.',
                style: TextStyle(fontSize: 12, color: Neumo.textSub(ctx)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final generated =
                            BackupPassphraseService.generatePassphrase();
                        await service.setPassphrase(generated);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        _showPassphraseSheet(context);
                      },
                      icon: const Icon(Icons.autorenew, size: 18),
                      label: const Text('Buat baru'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        final input = await _promptPassphrase(ctx);
                        if (input == null) return;
                        await service.setPassphrase(input);
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passphrase diperbarui')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Set'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
