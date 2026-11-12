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
                  'note_app_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
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
              allowedExtensions: ['zip'],
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
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Gagal restore: $e')),
              );
            }
          },
        ),
      ],
    );
  }

  /// Menampilkan dialog opsi restore: kembali ke file picker biasa atau lanjut ke manual.
  Future<String?> _showRestoreOptionsDialog(BuildContext context) async {
    return await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Cara Restore'),
        content: const Text(
          'File backup tidak ditemukan di path sebelumnya. Apakah Anda ingin memilih file secara manual?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'manual'),
            child: const Text('Pilih File Manual'),
          ),
        ],
      ),
    ) ??
        null;
  }
}
