import 'package:flutter/material.dart';

/// Neumorphism design tokens + helper widgets.
///
/// Prinsip:
/// - Warna elemen = warna background (blend)
/// - Shadow ganda: terang (kiri-atas) + gelap (kanan-bawah)
/// - Radius besar, gak ada border tebal
/// - Light & Dark mode support

class Neumo {
  Neumo._();

  // ==== LIGHT MODE ====
  static const Color lightBg = Color(0xFFEAEEF3);
  static const Color lightShadowDark = Color(0xFFC5CCD6);
  static const Color lightShadowLight = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF3A4252);
  static const Color lightTextSub = Color(0xFF6B7280);
  static const Color lightAccent = Color(0xFF6750A4);

  // ==== DARK MODE ====
  static const Color darkBg = Color(0xFF1E2128);
  static const Color darkShadowDark = Color(0xFF14161B);
  static const Color darkShadowLight = Color(0xFF2A2E37);
  static const Color darkText = Color(0xFFE4E6EB);
  static const Color darkTextSub = Color(0xFF9CA3AF);
  static const Color darkAccent = Color(0xFFB794F6);

  // ==== HELPERS ====
  static Color bg(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkBg : lightBg;

  static Color text(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkText : lightText;

  static Color textSub(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkTextSub : lightTextSub;

  static Color accent(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkAccent : lightAccent;

  static Color shadowDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkShadowDark : lightShadowDark;

  static Color shadowLight(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark ? darkShadowLight : lightShadowLight;

  /// Shadow neumo — raised (timbul)
  static List<BoxShadow> raised(BuildContext c, {double blur = 8, double offset = 4}) => [
    BoxShadow(
      color: shadowDark(c),
      offset: Offset(offset, offset),
      blurRadius: blur,
    ),
    BoxShadow(
      color: shadowLight(c),
      offset: Offset(-offset, -offset),
      blurRadius: blur,
    ),
  ];

  /// Shadow neumo — pressed (tenggelam)
  static List<BoxShadow> pressed(BuildContext c, {double blur = 4, double offset = 2}) => [
    BoxShadow(
      color: shadowDark(c),
      offset: Offset(-offset, -offset),
      blurRadius: blur,
    ),
    BoxShadow(
      color: shadowLight(c),
      offset: Offset(offset, offset),
      blurRadius: blur,
    ),
  ];

  /// Shadow neumo — flat (soft)
  static List<BoxShadow> soft(BuildContext c, {double blur = 6, double offset = 2}) => [
    BoxShadow(
      color: shadowDark(c).withOpacity(0.5),
      offset: Offset(offset, offset),
      blurRadius: blur,
    ),
    BoxShadow(
      color: shadowLight(c).withOpacity(0.8),
      offset: Offset(-offset, -offset),
      blurRadius: blur,
    ),
  ];
}

/// Card neumorphism — raised, dengan gradient halus.
class NeumoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;
  final bool pressed;
  final Color? color;

  const NeumoCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 16,
    this.onTap,
    this.pressed = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = color ?? Neumo.bg(context);
    final shadows = pressed ? Neumo.pressed(context) : Neumo.raised(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadows,
        ),
        child: child,
      ),
    );
  }
}

/// Tombol icon neumorphism.
class NeumoIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double radius;
  final Color? iconColor;

  const NeumoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 48,
    this.radius = 14,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Neumo.bg(context),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: Neumo.raised(context, blur: 6, offset: 3),
        ),
        child: Icon(
          icon,
          color: iconColor ?? Neumo.text(context),
          size: size * 0.45,
        ),
      ),
    );
  }
}

/// FAB neumorphism — bulat, raised dengan accent.
class NeumoFab extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? color;

  const NeumoFab({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 60,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? Neumo.accent(context);
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.4),
              offset: const Offset(0, 6),
              blurRadius: 12,
            ),
            BoxShadow(
              color: Neumo.shadowLight(context).withOpacity(0.6),
              offset: const Offset(-3, -3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.42),
      ),
    );
  }
}

/// Chip/Tag neumorphism.
class NeumoChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const NeumoChip({
    super.key,
    required this.label,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : Neumo.bg(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected
              ? Neumo.pressed(context, blur: 3, offset: 1)
              : Neumo.raised(context, blur: 4, offset: 2),
          border: selected ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : Neumo.text(context),
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
