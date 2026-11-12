import 'package:flutter/material.dart';

import '../services/image_attachment_service.dart';
import 'image_picker_sheet.dart';

/// Sheet generik untuk mengelola background aplikasi (global) maupun
/// background sidebar (drawer).
///
/// Dua implementasi lama di `settings_screen.dart` nyaris identik; fungsi ini
/// menggabungkannya jadi satu widget yang menerima parameter.
/// Copy/teks UI dipertahankan persis seperti implementasi sebelumnya.
///
/// [pickImage] adalah seam untuk memilih file gambar (default: galeri/kamera).
/// Inject fungsi sendiri saat menguji.
Future<void> showBackgroundSheet(
  BuildContext context, {
  required String title,
  required bool hasBackground,
  required String? backgroundPath,
  required double opacity,
  required Future<void> Function(String path) onPick,
  required Future<void> Function(double value) onOpacity,
  required Future<void> Function() onRemove,
  String opacityTitle = 'Transparansi Background',
  Future<String?> Function(BuildContext context)? pickImage,
}) async {
  // `hasBackground` dan `backgroundPath` saling melengkapi: kalau salah satu
  // menandakan ada background, item transparansi & hapus tetap ditampilkan.
  final adaBackground =
      hasBackground || (backgroundPath != null && backgroundPath.isNotEmpty);
  final pilihGambar = pickImage ?? pickBackgroundImage;

  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Pilih Gambar'),
            subtitle: const Text('Gunakan gambar dari galeri/kamera'),
            onTap: () async {
              Navigator.pop(ctx);
              final path = await pilihGambar(context);
              if (path != null) {
                await onPick(path);
              }
            },
          ),
          if (adaBackground) ...[
            ListTile(
              leading: const Icon(Icons.opacity),
              title: const Text('Atur Transparansi'),
              subtitle: Text('${(opacity * 100).round()}%'),
              onTap: () {
                Navigator.pop(ctx);
                showBackgroundOpacitySheet(
                  context,
                  title: opacityTitle,
                  opacity: opacity,
                  onChanged: onOpacity,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Hapus Gambar'),
              onTap: () async {
                Navigator.pop(ctx);
                await onRemove();
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Pilih gambar dari galeri atau kamera. Return null kalau user batal.
Future<String?> pickBackgroundImage(BuildContext context) async {
  final source = await showImageSourceSheet(context);
  if (source == null) return null;

  String? path;
  if (source == 'gallery') {
    final files = await ImageAttachmentService().pickFromGallery();
    if (files.isNotEmpty) path = files.first;
  } else {
    path = await ImageAttachmentService().pickFromCamera();
  }
  return path;
}

/// Sheet untuk mengatur nilai transparansi background.
/// Nilai baru langsung diteruskan ke [onChanged] setiap slider digeser.
void showBackgroundOpacitySheet(
  BuildContext context, {
  required String title,
  required double opacity,
  required Future<void> Function(double value) onChanged,
}) {
  var value = opacity;
  showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.brightness_low, size: 18),
                Expanded(
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 20,
                    label: '${(value * 100).round()}%',
                    onChanged: (v) {
                      setLocal(() => value = v);
                      onChanged(v);
                    },
                  ),
                ),
                const Icon(Icons.brightness_high, size: 18),
              ],
            ),
            Center(
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Semakin kecil % → background lebih transparan',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    ),
  );
}
