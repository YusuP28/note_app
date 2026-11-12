import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:note_app/providers/settings_provider.dart';
import 'package:note_app/widgets/background_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'global_bg_path': '/tmp/global.png',
      'global_bg_opacity': 0.3,
      'drawer_bg_path': '/tmp/drawer.png',
      'drawer_bg_opacity': 0.5,
    });
  });

  /// Pump provider + MaterialApp, lalu buka sheet lewat tombol pemicu.
  Future<SettingsProvider> openSheet(
    WidgetTester tester, {
    required String title,
    required bool hasBackground,
    required String? backgroundPath,
    required double opacity,
    required Future<void> Function(String path) onPick,
    required Future<void> Function(double value) onOpacity,
    required Future<void> Function() onRemove,
    String opacityTitle = 'Transparansi Background',
    Future<String?> Function(BuildContext context)? pickImage,
  }) async {
    final settings = SettingsProvider();
    await settings.load();

    await tester.pumpWidget(
      ChangeNotifierProvider<SettingsProvider>.value(
        value: settings,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => TextButton(
                onPressed: () => showBackgroundSheet(
                  ctx,
                  title: title,
                  hasBackground: hasBackground,
                  backgroundPath: backgroundPath,
                  opacity: opacity,
                  opacityTitle: opacityTitle,
                  onPick: onPick,
                  onOpacity: onOpacity,
                  onRemove: onRemove,
                  pickImage: pickImage,
                ),
                child: const Text('Buka Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Sheet'));
    await tester.pumpAndSettle();
    return settings;
  }

  group('showBackgroundSheet', () {
    testWidgets('menampilkan judul yang diberikan', (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      expect(find.text('Background Aplikasi (Global)'), findsOneWidget);
    });

    testWidgets(
        'menampilkan judul sheet sidebar dengan teks yang sama persis',
        (tester) async {
      await openSheet(
        tester,
        title: 'Background Sidebar (Drawer)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.5,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      expect(find.text('Background Sidebar (Drawer)'), findsOneWidget);
    });

    testWidgets('menampilkan item "Pilih Gambar" beserta subjudulnya',
        (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      expect(find.text('Pilih Gambar'), findsOneWidget);
      expect(find.text('Gunakan gambar dari galeri/kamera'), findsOneWidget);
    });

    testWidgets(
        'tidak ada tombol hapus dan transparansi kalau belum ada background',
        (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      expect(find.text('Hapus Gambar'), findsNothing);
      expect(find.text('Atur Transparansi'), findsNothing);
    });

    testWidgets('ada tombol hapus kalau sudah ada background', (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: true,
        backgroundPath: '/tmp/global.png',
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      expect(find.text('Hapus Gambar'), findsOneWidget);
      expect(find.text('Atur Transparansi'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
    });

    testWidgets('memanggil onPick dengan path saat "Pilih Gambar" ditekan',
        (tester) async {
      String? dipilih;
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (path) async => dipilih = path,
        onOpacity: (_) async {},
        onRemove: () async {},
        pickImage: (_) async => '/tmp/baru.png',
      );

      await tester.tap(find.text('Pilih Gambar'));
      await tester.pumpAndSettle();

      expect(dipilih, '/tmp/baru.png');
    });

    testWidgets('onPick tidak dipanggil kalau picking dibatalkan',
        (tester) async {
      var dipanggil = false;
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (_) async => dipanggil = true,
        onOpacity: (_) async {},
        onRemove: () async {},
        pickImage: (_) async => null,
      );

      await tester.tap(find.text('Pilih Gambar'));
      await tester.pumpAndSettle();

      expect(dipanggil, isFalse);
    });

    testWidgets('"Pilih Gambar" membuka sheet pilihan galeri/kamera',
        (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: false,
        backgroundPath: null,
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
      );

      await tester.tap(find.text('Pilih Gambar'));
      await tester.pumpAndSettle();

      expect(find.text('Dari Galeri'), findsOneWidget);
      expect(find.text('Dari Kamera'), findsOneWidget);
    });

    testWidgets('memanggil onRemove saat "Hapus Gambar" ditekan',
        (tester) async {
      var dihapus = false;
      await openSheet(
        tester,
        title: 'Background Sidebar (Drawer)',
        hasBackground: true,
        backgroundPath: '/tmp/drawer.png',
        opacity: 0.5,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async => dihapus = true,
      );

      await tester.tap(find.text('Hapus Gambar'));
      await tester.pumpAndSettle();

      expect(dihapus, isTrue);
    });

    testWidgets('membuka sheet transparansi dengan judul dan nilai awal',
        (tester) async {
      await openSheet(
        tester,
        title: 'Background Aplikasi (Global)',
        hasBackground: true,
        backgroundPath: '/tmp/global.png',
        opacity: 0.3,
        onPick: (_) async {},
        onOpacity: (_) async {},
        onRemove: () async {},
        opacityTitle: 'Transparansi Background Global',
      );

      await tester.tap(find.text('Atur Transparansi'));
      await tester.pumpAndSettle();

      expect(find.text('Transparansi Background Global'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('menggeser slider memanggil onOpacity dengan nilai baru',
        (tester) async {
      final nilai = <double>[];
      await openSheet(
        tester,
        title: 'Background Sidebar (Drawer)',
        hasBackground: true,
        backgroundPath: '/tmp/drawer.png',
        opacity: 0.5,
        onPick: (_) async {},
        onOpacity: (v) async => nilai.add(v),
        onRemove: () async {},
        opacityTitle: 'Transparansi Background Sidebar',
      );

      await tester.tap(find.text('Atur Transparansi'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Slider), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(nilai, isNotEmpty);
      expect(nilai.last, isNot(0.5));
    });
  });

  group('SettingsProvider integrasi', () {
    testWidgets('nilai dari SettingsProvider bisa dipakai sebagai argumen sheet',
        (tester) async {
      final settings = SettingsProvider();
      await settings.load();

      expect(settings.hasGlobalBackground, isTrue);
      expect(settings.globalBgPath, '/tmp/global.png');
      expect(settings.globalBgOpacity, 0.3);
      expect(settings.hasDrawerBackground, isTrue);
      expect(settings.drawerBgOpacity, 0.5);
    });
  });
}
