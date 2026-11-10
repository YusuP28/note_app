/// Logika inti aplikasi Catatanku - pure Dart (tanpa Flutter).
///
/// Dipisah dari package `note_app` agar bisa diuji dengan `dart test`
/// di lingkungan tanpa Flutter SDK.
library note_app_core;

export 'src/backup_crypto.dart';
export 'src/backup_envelope.dart';
export 'src/lockout_policy.dart';
export 'src/media_path_guard.dart';
export 'src/note_cipher.dart';
export 'src/pbkdf2.dart';
export 'src/sort_options.dart';
