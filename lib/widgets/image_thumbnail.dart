import 'dart:io';
import 'package:flutter/material.dart';

class ImageThumbnail extends StatelessWidget {
  final String path;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final double size;

  const ImageThumbnail({
    super.key,
    required this.path,
    required this.onDelete,
    required this.onTap,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.black26),
              image: DecorationImage(
                image: FileImage(file),
                fit: BoxFit.cover,
                onError: (_, __) {},
              ),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 10,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
