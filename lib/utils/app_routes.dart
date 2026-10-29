import 'package:flutter/material.dart';

import '../widgets/global_background.dart';

/// Route transparan untuk layar yang memakai background global.
///
/// `opaque: false` membuat route di bawahnya tetap hidup selama transisi,
/// sehingga background global tidak sempat berkedip menjadi warna solid.
/// Halaman tujuan tetap dibungkus [GlobalBackground] agar konten layar
/// sebelumnya tidak tembus (overlap) di belakang Scaffold yang transparan.
Route<T> globalBackgroundRoute<T>(WidgetBuilder builder) {
  return PageRouteBuilder<T>(
    opaque: false,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, secondaryAnimation) =>
        GlobalBackground(child: builder(context)),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(opacity: curved, child: child);
    },
  );
}
