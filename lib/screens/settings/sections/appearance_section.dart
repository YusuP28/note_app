import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/settings_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../widgets/background_sheet.dart';
import 'section_header.dart';

/// Section "Tampilan" di layar pengaturan.
///
/// Berisi mode gelap + pengelolaan background aplikasi (global) dan
/// background sidebar (drawer).
///
/// Teks UI, ikon, dan urutan tile sama persis dengan versi lama; yang
/// berubah hanya letak kodenya.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settings = context.watch<SettingsProvider>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SettingsSectionHeader('Tampilan'),
        SwitchListTile(
          secondary: const Icon(Icons.dark_mode_outlined),
          title: const Text('Mode Gelap'),
          value: themeProvider.isDark,
          onChanged: (val) => themeProvider.setMode(
            val ? ThemeMode.dark : ThemeMode.light,
          ),
        ),
        ListTile(
          leading: const Icon(Icons.wallpaper_outlined),
          title: const Text('Background Aplikasi (Global)'),
          subtitle: Text(
            settings.hasGlobalBackground
                ? 'Aktif • transparansi ${(settings.globalBgOpacity * 100).round()}%'
                : 'Tidak aktif',
          ),
          onTap: () => showBackgroundSheet(
            context,
            title: 'Background Aplikasi (Global)',
            hasBackground: settings.hasGlobalBackground,
            backgroundPath: settings.globalBgPath,
            opacity: settings.globalBgOpacity,
            opacityTitle: 'Transparansi Background Global',
            onPick: (path) => settings.setGlobalBackground(path),
            onOpacity: (value) => settings.setGlobalBackgroundOpacity(value),
            onRemove: () => settings.setGlobalBackground(null),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.menu_outlined),
          title: const Text('Background Sidebar (Drawer)'),
          subtitle: Text(
            settings.hasDrawerBackground
                ? 'Aktif • transparansi ${(settings.drawerBgOpacity * 100).round()}%'
                : 'Tidak aktif',
          ),
          onTap: () => showBackgroundSheet(
            context,
            title: 'Background Sidebar (Drawer)',
            hasBackground: settings.hasDrawerBackground,
            backgroundPath: settings.drawerBgPath,
            opacity: settings.drawerBgOpacity,
            opacityTitle: 'Transparansi Background Sidebar',
            onPick: (path) => settings.setDrawerBackground(path),
            onOpacity: (value) => settings.setDrawerBackgroundOpacity(value),
            onRemove: () => settings.setDrawerBackground(null),
          ),
        ),
      ],
    );
  }
}
