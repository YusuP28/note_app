import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_provider.dart';
import '../themes/neumo.dart';

/// Background global aplikasi.
///
/// Dipasang di root `MaterialApp.builder`, sehingga tampil di belakang semua
/// route. Layar utama cukup memakai `Scaffold` transparan agar background ini
/// tembus. Layar catatan (`EditScreen`) tetap memakai Scaffold opaque +
/// background catatan sendiri, jadi otomatis menimpa background global.
class GlobalBackground extends StatelessWidget {
  final Widget child;

  const GlobalBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final path = settings.globalBgPath;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Warna dasar — dipakai saat belum ada gambar global.
        Container(color: Neumo.bg(context)),
        if (path != null && path.isNotEmpty)
          Positioned.fill(
            child: SizedBox(
              // Kunci tinggi layar penuh agar tidak bergerak saat keyboard muncul.
              height: MediaQuery.of(context).size.height,
              child: Opacity(
                opacity: settings.globalBgOpacity,
                child: Image.file(
                  File(path),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  cacheWidth: 1080,
                  errorBuilder: (_, __, ___) => const SizedBox(),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}
