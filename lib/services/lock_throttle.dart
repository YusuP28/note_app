/// Aturan pembatasan percobaan PIN dan backup code.
///
/// Sengaja tanpa import Flutter/shared_preferences supaya bisa diuji
/// dengan Dart SDK biasa: `dart test/lock_throttle_test.dart`.
class LockThrottle {
  static const int freeAttempts = 5;
  static const int shortLockSeconds = 30;
  static const int longLockSeconds = 300;

  /// Lama kunci (detik) setelah [failCount] kali gagal. 0 = belum dikunci.
  static int secondsAfter(int failCount) {
    if (failCount >= freeAttempts * 2) return longLockSeconds;
    if (failCount >= freeAttempts) return shortLockSeconds;
    return 0;
  }

  /// Sisa kunci dalam detik. [nowMs] dan [lockUntilMs] pakai epoch milidetik.
  static int remaining(int lockUntilMs, int nowMs) {
    final left = lockUntilMs - nowMs;
    return left > 0 ? (left / 1000).ceil() : 0;
  }
}
