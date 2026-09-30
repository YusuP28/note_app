import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart' show Embed;
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
        padding: const EdgeInsets.all(12),
        color: Colors.red.withOpacity(0.1),
        child: const Text('[Gambar tidak ditemukan]'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Container(
            padding: const EdgeInsets.all(12),
            color: Colors.red.withOpacity(0.1),
            child: const Text('[Gagal memuat gambar]'),
          ),
        ),
      ),
    );
  }
}
