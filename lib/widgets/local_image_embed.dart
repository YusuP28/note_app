import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';

class LocalImageEmbedBuilder extends EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final path = embedContext.node.value.data as String;
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
