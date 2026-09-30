import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/src/models/documents/nodes/leaf.dart' as leaf;

class LocalImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(
    BuildContext context,
    QuillController controller,
    leaf.Embed node,
    bool readOnly,
    bool inline,
    TextStyle textStyle,
  ) {
    final path = node.value.data as String;
    final file = File(path);

    if (!file.existsSync()) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: const [
            Icon(Icons.broken_image, size: 16, color: Colors.red),
            SizedBox(width: 8),
            Text('Gambar tidak ditemukan', style: TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    // Ambil ukuran layar untuk batasi gambar
    final screenW = MediaQuery.of(context).size.width;
    final maxW = 60.0; // lebar maksimal (kecil)
    final maxH = 60.0; // tinggi maksimal (kecil)

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: () => _showFullscreen(context, file),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxW,
            maxHeight: maxH,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: maxW,
                  height: maxH,
                  errorBuilder: (_, __, ___) => Container(
                    width: maxW,
                    height: maxH,
                    color: Colors.red.withOpacity(0.1),
                    alignment: Alignment.center,
                    child: const Text('[Gagal memuat]'),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(Icons.zoom_in, size: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context, File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Image.file(file),
            ),
          ),
        ),
      ),
    );
  }
}
