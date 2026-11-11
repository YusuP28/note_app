import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/providers/note_provider.dart';
import 'package:note_app/providers/settings_provider.dart';
import 'package:note_app/providers/theme_provider.dart';
import 'package:note_app/screens/settings/sections/appearance_section.dart';
import 'package:note_app/screens/settings/sections/backup_section.dart';
import 'package:note_app/screens/settings/sections/security_section.dart';
import 'package:note_app/screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  /// Pump satu section di dalam MaterialApp + MultiProvider.
  Future<void> pumpSection(WidgetTester tester, Widget section) async {
    final theme = ThemeProvider();
    final settings = SettingsProvider();
    await theme.load();
    await settings.load();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: theme),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
          ChangeNotifierProvider<NoteProvider>.value(value: NoteProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: section),
          ),
        ),
      ),
    );
  }

  group('Section pengaturan', () {
    testWidgets('AppearanceSection bisa dirender tanpa error', (tester) async {
      await pumpSection(tester, const AppearanceSection());

      expect(tester.takeException(), isNull);
      expect(find.text('TAMPILAN'), findsOneWidget);
      expect(find.text('Mode Gelap'), findsOneWidget);
      expect(find.text('Background Aplikasi (Global)'), findsOneWidget);
      expect(find.text('Background Sidebar (Drawer)'), findsOneWidget);
    });

    testWidgets('BackupSection bisa dirender tanpa error', (tester) async {
      await pumpSection(tester, const BackupSection());

      expect(tester.takeException(), isNull);
      expect(find.text('BACKUP LOKAL'), findsOneWidget);
      expect(find.text('Passphrase Backup'), findsOneWidget);
      expect(find.text('Backup Data (ZIP)'), findsOneWidget);
      expect(find.text('Restore dari File'), findsOneWidget);
      expect(find.text('Bersihkan Sampah Lama'), findsOneWidget);
    });

    testWidgets('SecuritySection bisa dirender tanpa error', (tester) async {
      await pumpSection(tester, const SecuritySection());

      expect(tester.takeException(), isNull);
      expect(find.text('KEAMANAN'), findsOneWidget);
      expect(find.text('Kunci Aplikasi'), findsOneWidget);
      expect(find.text('Buka Catatan dengan Sidik Jari'), findsOneWidget);
    });

    testWidgets('SettingsScreen merakit semua section', (tester) async {
      final theme = ThemeProvider();
      final settings = SettingsProvider();
      await theme.load();
      await settings.load();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>.value(value: theme),
            ChangeNotifierProvider<SettingsProvider>.value(value: settings),
            ChangeNotifierProvider<NoteProvider>.value(value: NoteProvider()),
          ],
          child: const MaterialApp(home: SettingsScreen()),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AppearanceSection), findsOneWidget);
      expect(find.text('TAMPILAN'), findsOneWidget);

      // Section yang jauh di bawah harus di-scroll dulu supaya dibangun.
      await tester.scrollUntilVisible(find.byType(BackupSection), 400);
      expect(find.byType(BackupSection), findsOneWidget);
      await tester.scrollUntilVisible(find.byType(SecuritySection), 400);
      expect(find.byType(SecuritySection), findsOneWidget);
      await tester.scrollUntilVisible(find.text('TENTANG'), 400);
      expect(find.text('TENTANG'), findsOneWidget);
    });
  });
}
