import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'providers/note_provider.dart';
import 'providers/notebook_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/settings_provider.dart';
import 'services/google_drive_service.dart';
import 'screens/notes/home_screen.dart';
import 'screens/alarm/alarm_page_screen.dart';
import 'services/migration_service.dart';
import 'services/backup_service.dart';
import 'services/alarm_service.dart';
import 'services/auto_backup_service.dart';
import 'services/image_attachment_service.dart';
import 'themes/app_theme.dart';
import 'utils/locale_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocale();
  await MigrationService().migrateIfNeeded();
  await BackupService().autoBackup();

  // PRELOAD settings & theme — cegah race condition
  final settings = SettingsProvider();
  await settings.load();
  final theme = ThemeProvider();
  await theme.load();

  // Siapkan auto-backup service — dijalankan setelah UI muncul
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    ImageAttachmentService().setUseOriginal(settings.useOriginalQuality);
    final gd = GoogleDriveService();
    await gd.signInSilently();
    await AutoBackupService().checkAndRun(settings);
  });

  runApp(NoteApp(settings: settings, theme: theme));
}

class NoteApp extends StatelessWidget {
  final SettingsProvider settings;
  final ThemeProvider theme;

  const NoteApp({super.key, required this.settings, required this.theme});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
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
