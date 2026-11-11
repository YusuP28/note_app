import 'package:flutter/material.dart';

import '../../../themes/neumo.dart';

/// Judul section di layar pengaturan (mis. "TAMPILAN").
///
/// Dipakai bersama oleh `settings_screen.dart` dan masing-masing file
/// section supaya gaya header selalu sama.
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.text, {super.key});

  /// Teks section. Otomatis dikapitalisasi saat dirender.
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: Neumo.textSub(context),
          ),
        ),
      );
}
