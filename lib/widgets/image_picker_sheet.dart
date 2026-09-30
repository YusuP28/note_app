import 'package:flutter/material.dart';

Future<String?> showImageSourceSheet(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tambah Gambar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Dari Galeri'),
            subtitle: const Text('Pilih 1 atau lebih gambar'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Dari Kamera'),
            subtitle: const Text('Ambil foto langsung'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
