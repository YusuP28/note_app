import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'providers/note_provider.dart';
import 'providers/notebook_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/notes/home_screen.dart';
import 'screens/alarm/alarm_page_screen.dart';
import 'services/migration_service.dart';
import 'services/backup_service.dart';
import 'services/auto_backup_service.dart';
import 'services/database_service.dart';
import 'services/image_attachment_service.dart';
import 'services/trash_purge_service.dart';
import 'themes/app_theme.dart';
import 'utils/locale_init.dart';
import 'widgets/global_background.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Request POST_NOTIFICATIONS (Android 13+) + SCHEDULE_EXACT_ALARM
  await _requestPermissions();

  await initLocale();
  await MigrationService().migrateIfNeeded();

  // Aktifkan enkripsi konten catatan terkunci (kunci dari Android Keystore).
  await DatabaseService().initContentCipher();

  // Catatan yang dikunci SEBELUM fitur enkripsi aktif masih plaintext di
  // SQLite (dan ikut ter-export ke backup). Enkripsi sekarang, sebelum
  // auto-backup di bawah sempat menyalin baris tersebut.
  await _encryptExistingLockedNotes();

  // SATU instance NoteProvider untuk seluruh aplikasi: dipakai provider tree
  // (lihat NoteApp) DAN auto-purge di bawah. Kalau purge memakai instance
  // sendiri, terjadi load penuh kedua di startup + instance yatim yang
  // tidak pernah di-dispose.
  final noteProvider = NoteProvider();

  // Auto-purge sampah lama (> 30 hari) - otomatis, bukan hanya tombol manual
  // di Settings. Kegagalan tidak boleh menggagalkan start aplikasi.
  //
  // Urutan: purge dijalankan SEBELUM UI mount, memakai instance provider yang
  // sama. `purgeOldTrash` memuat ulang daftar (load()) di akhir, jadi data
  // yang tampil di UI sudah bebas dari sampah lama.
  try {
    await TrashPurgeService(
      purge: (days) => noteProvider.purgeOldTrash(days: days),
    ).runIfDue(days: 30);
  } catch (e) {
    debugPrint('auto-purge gagal: $e');
  }

  await BackupService().autoBackup();

  // PRELOAD settings & theme — cegah race condition
  final settings = SettingsProvider();
  await settings.load();
  final theme = ThemeProvider();
  await theme.load();

  // Siapkan auto-backup service — dijalankan setelah UI muncul.
  // Google Sign-In TIDAK dipanggil di sini: koneksi ke pihak ketiga hanya
  // terjadi kalau user benar-benar mengaktifkan auto-backup ke Drive.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    ImageAttachmentService().setUseOriginal(settings.useOriginalQuality);
    await AutoBackupService().checkAndRun(settings);
  });

  runApp(NoteApp(
    settings: settings,
    theme: theme,
    noteProvider: noteProvider,
  ));
}

/// Request permission runtime: notifikasi (Android 13+) + alarm exact
Future<void> _requestPermissions() async {
  try {
    // POST_NOTIFICATIONS (Android 13+)
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    // SCHEDULE_EXACT_ALARM (Android 12+) — harus lewat intent khusus
    if (!await Permission.scheduleExactAlarm.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
  } catch (e) {
    debugPrint('permission request error: $e');
  }
}

/// Enkripsi catatan terkunci lama yang dibuat sebelum fitur enkripsi aktif.
///
/// Idempoten: hanya menulis baris yang isinya benar-benar berubah, sehingga
/// aman dipanggil di setiap start. Kegagalan tidak boleh menggagalkan app -
/// catatan lama tetap terbaca sebagai plaintext (jalur fallback `NoteCipher`).
Future<void> _encryptExistingLockedNotes() async {
  try {
    final dbService = DatabaseService();
    final cipher = dbService.cipher;
    if (!cipher.isEnabled) return;

    final db = await dbService.database;
    final rows = await db.query(
      'notes',
      columns: ['id', 'content', 'plain_text', 'is_locked'],
      where: 'is_locked = 1',
    );

    var updated = 0;
    for (final row in rows) {
      final encrypted = cipher.encryptRow(row);
      if (encrypted['content'] == row['content'] &&
          encrypted['plain_text'] == row['plain_text']) {
        continue;
      }
      await db.update(
        'notes',
        {
          'content': encrypted['content'],
          'plain_text': encrypted['plain_text'],
        },
        where: 'id = ?',
        whereArgs: [row['id']],
      );
      updated++;
    }
    if (updated > 0) {
      debugPrint('backfill enkripsi: $updated catatan terkunci dienkripsi');
    }
  } catch (e) {
    debugPrint('backfill enkripsi gagal: $e');
  }
}

class NoteApp extends StatelessWidget {
  final SettingsProvider settings;
  final ThemeProvider theme;

  /// Instance NoteProvider yang dipakai bersama dengan auto-purge.
  final NoteProvider noteProvider;

  const NoteApp({
    super.key,
    required this.settings,
    required this.theme,
    required this.noteProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: settings),
        // `.value` — instance yang sama dengan yang dipakai auto-purge,
        // jadi tidak ada provider kedua yang melakukan load penuh sendiri.
        ChangeNotifierProvider.value(value: noteProvider),
        ChangeNotifierProvider(create: (_) => NotebookProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, t, _) {
          return MaterialApp(
            title: 'Catatanku',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(t.seed),
            darkTheme: AppTheme.dark(t.seed),
            themeMode: t.mode,
            // Background global di belakang seluruh route.
            builder: (context, child) => GlobalBackground(
              child: child ?? const SizedBox.shrink(),
            ),
            home: const _Launcher(),
          );
        },
      ),
    );
  }
}

class _Launcher extends StatefulWidget {
  const _Launcher();

  @override
  State<_Launcher> createState() => _LauncherState();
}

class _LauncherState extends State<_Launcher> {
  static const _channel = MethodChannel('note_app/alarm_page');
  bool _isAlarm = false;
  bool _checked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_checked) {
      _checked = true;
      _check();
    }
  }

  Future<void> _check() async {
    try {
      final noteId = await _channel.invokeMethod<String>('getNoteId');
      if ((noteId != null && noteId.isNotEmpty) && mounted) {
        setState(() => _isAlarm = true);
      }
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _isAlarm ? const AlarmPageScreen() : const HomeScreen();
  }
}
