/// Policy lockout untuk PIN dan backup code.
///
/// Dipisah dari Flutter agar aturan throttle bisa diuji sebagai fungsi murni.
library;

/// Keputusan lockout untuk satu kali percobaan gagal.
class LockoutDecision {
  /// Detik tersisa untuk lockout (0 = tidak terkunci).
  final int lockSeconds;

  /// Jumlah kegagalan kumulatif.
  final int failCount;

  const LockoutDecision(this.lockSeconds, this.failCount);

  bool get isLocked => lockSeconds > 0;
}

/// Aturan lockout yang sama untuk PIN dan backup code.
///
/// - 5 gagal  -&gt; kunci 30 detik
/// - 10 gagal -&gt; kunci 5 menit
///
/// Backup code DAN PIN memakai fungsi yang sama supaya tidak ada jalur
/// bypass: sebelumnya `verifyBackupCode` sama sekali tidak mengecek lockout
/// maupun menambah `_kFailCount`, sehingga 1 juta kombinasi bisa dicoba bebas.
class LockoutPolicy {
  static const int freeAttempts = 5;
  static const int shortLockSeconds = 30;
  static const int longLockSeconds = 300;

  /// Hitung lockout berdasarkan jumlah kegagalan kumulatif.
  static LockoutDecision decide(int failCount) {
    final fails = failCount < 0 ? 0 : failCount;
    final int seconds;
    if (fails >= freeAttempts * 2) {
      seconds = longLockSeconds;
    } else if (fails >= freeAttempts) {
      seconds = shortLockSeconds;
    } else {
      seconds = 0;
    }
    return LockoutDecision(seconds, fails);
  }
}
