import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/note_provider.dart';
import 'providers/notebook_provider.dart';
import 'providers/tag_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/notes/home_screen.dart';
import 'services/migration_service.dart';
import 'services/backup_service.dart';
import 'themes/app_theme.dart';
import 'utils/locale_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocale();
  await MigrationService().migrateIfNeeded();
  await BackupService().autoBackup();
  runApp(const NoteApp());
}

class NoteApp extends StatelessWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()..load()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => NotebookProvider()),
        ChangeNotifierProvider(create: (_) => TagProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: 'Catatanku',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(theme.seed),
            darkTheme: AppTheme.dark(theme.seed),
            themeMode: theme.mode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
