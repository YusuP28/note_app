import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

/// Service untuk PIN lock aplikasi.
/// - PIN & backup code disimpan sebagai PBKDF2-HMAC-SHA256 (salted)
/// - Hash legacy SHA-256 dimigrasi otomatis saat PIN benar
/// - Throttle: 5 gagal = 30 detik, 10 gagal = 5 menit
/// - Hint + backup code (6 digit, sekali pakai)
/// - Support fingerprint (local_auth)
class LockService {
  static final LockService _i = LockService._();
  factory LockService() => _i;
  LockService._();

  static const _kPinHash = 'lock_pin_hash';
  static const _kPinHint = 'lock_pin_hint';
  static const _kBackupCode = 'lock_backup_code'; // legacy plaintext
  static const _kBackupCodeHash = 'lock_backup_code_hash';
  static const _kEnabled = 'lock_enabled';
  static const _kFingerprint = 'lock_fingerprint';
  static const _kFailCount = 'lock_fail_count';
  static const _kLockUntil = 'lock_lock_until';

  static const int _pbkdf2Iterations = 210000;
  static const int _saltBytes = 16;
  static const int _keyBytes = 32;
  static const int _freeAttempts = 5;
  static const int _shortLockSeconds = 30;
  static const int _longLockSeconds = 300;

  final LocalAuthentication _auth = LocalAuthentication();

  // ==== STATE ====
  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kEnabled) ?? false;
  }

  Future<bool> isFingerprintEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kFingerprint) ?? false;
  }

  Future<String?> getHint() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kPinHint);
  }

  // ==== SET PIN ====
  Future<String> setPin(String pin, {String? hint}) async {
    final p = await SharedPreferences.getInstance();
    final hash = await _derive(pin);
    final code = _generateBackupCode();
    final codeHash = await _derive(code);

    await p.setString(_kPinHash, hash);
    await p.setString(_kBackupCodeHash, codeHash);
    await p.remove(_kBackupCode);
    await p.setInt(_kFailCount, 0);
    await p.remove(_kLockUntil);
    await p.setBool(_kEnabled, true);
    if (hint != null && hint.isNotEmpty) {
      await p.setString(_kPinHint, hint);
    } else {
      await p.remove(_kPinHint);
    }
    return code;
  }

  Future<void> updateHint(String? hint) async {
    final p = await SharedPreferences.getInstance();
    if (hint == null || hint.isEmpty) {
      await p.remove(_kPinHint);
    } else {
      await p.setString(_kPinHint, hint);
    }
  }

  Future<void> disable() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kPinHash);
    await p.remove(_kPinHint);
    await p.remove(_kBackupCode);
    await p.remove(_kBackupCodeHash);
    await p.remove(_kFailCount);
    await p.remove(_kLockUntil);
    await p.setBool(_kEnabled, false);
    await p.setBool(_kFingerprint, false);
  }

  Future<void> setFingerprint(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFingerprint, enabled);
  }

  // ==== VERIFY ====
  /// Sisa waktu lockout dalam detik (0 = tidak terkunci).
  Future<int> lockoutRemainingSeconds() async {
    final p = await SharedPreferences.getInstance();
    final until = p.getInt(_kLockUntil) ?? 0;
    final left = until - DateTime.now().millisecondsSinceEpoch;
    return left > 0 ? (left / 1000).ceil() : 0;
  }

  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    if (await lockoutRemainingSeconds() > 0) return false;

    final stored = p.getString(_kPinHash);
    if (stored == null) return false;

    final ok = await _verifyHash(pin, stored);
    if (ok) {
      await p.setInt(_kFailCount, 0);
      await p.remove(_kLockUntil);
      // Migrasi hash legacy SHA-256 -> PBKDF2 (tanpa ubah PIN user).
      if (!_isPbkdf2(stored)) {
        await p.setString(_kPinHash, await _derive(pin));
      }
      return true;
    }

    final fails = (p.getInt(_kFailCount) ?? 0) + 1;
    await p.setInt(_kFailCount, fails);
    final lockSeconds = fails >= _freeAttempts * 2
        ? _longLockSeconds
        : (fails >= _freeAttempts ? _shortLockSeconds : 0);
    if (lockSeconds > 0) {
      await p.setInt(
        _kLockUntil,
        DateTime.now().millisecondsSinceEpoch + lockSeconds * 1000,
      );
    }
    return false;
  }

  Future<bool> verifyBackupCode(String code) async {
    final p = await SharedPreferences.getInstance();
    final normalized = code.trim();

    final storedHash = p.getString(_kBackupCodeHash);
    if (storedHash != null) {
      return _verifyHash(normalized, storedHash);
    }

    // Legacy: backup code tersimpan plaintext -> verifikasi lalu migrasi.
    final legacy = p.getString(_kBackupCode);
    if (legacy == null) return false;
    final ok = _constantTimeEquals(
      utf8.encode(legacy.trim()),
      utf8.encode(normalized),
    );
    if (ok) {
      await p.setString(_kBackupCodeHash, await _derive(normalized));
      await p.remove(_kBackupCode);
    }
    return ok;
  }

  /// Reset PIN pakai backup code (sekali pakai).
  /// Return backup code baru, atau null kalau gagal.
  Future<String?> resetWithBackupCode(
    String code,
    String newPin, {
    String? hint,
  }) async {
    if (!await verifyBackupCode(code)) return null;
    return setPin(newPin, hint: hint);
  }

  // ==== FINGERPRINT ====
  Future<bool> canUseBiometric() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported && canCheck;
    } catch (e) {
      debugPrint('biometric check err: $e');
      return false;
    }
  }

  Future<bool> authenticateBiometric({
    String reason = 'Verifikasi untuk membuka catatan terkunci',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('biometric auth err: $e');
      return false;
    }
  }

  // ==== HASH ====
  bool _isPbkdf2(String value) => value.startsWith('pbkdf2\$');

  Future<String> _derive(String value) async {
    final salt = _randomBytes(_saltBytes);
    final hash = await _pbkdf2(value, salt, _pbkdf2Iterations, _keyBytes);
    return 'pbkdf2\$$_pbkdf2Iterations\$${base64Encode(salt)}\$${base64Encode(hash)}';
  }

  Future<bool> _verifyHash(String value, String stored) async {
    if (_isPbkdf2(stored)) {
      final parts = stored.split(r'$');
      if (parts.length != 4) return false;
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations < 1000) return false;
      final salt = base64Decode(parts[2]);
      final expected = base64Decode(parts[3]);
      final actual = await _pbkdf2(value, salt, iterations, expected.length);
      return _constantTimeEquals(actual, expected);
    }
    // Legacy: SHA-256 hex tanpa salt.
    final legacy = sha256.convert(utf8.encode(value)).toString();
    return _constantTimeEquals(
      utf8.encode(legacy),
      utf8.encode(stored.toLowerCase()),
    );
  }

  Future<List<int>> _pbkdf2(
    String value,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    return compute(_pbkdf2Task, <String, Object>{
      'value': value,
      'salt': salt,
      'iterations': iterations,
      'keyLength': keyLength,
    });
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  List<int> _randomBytes(int length) {
    final rnd = Random.secure();
    return List<int>.generate(length, (_) => rnd.nextInt(256));
  }

  String _generateBackupCode() {
    final r = Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    return code;
  }
}

List<int> _pbkdf2Task(Map<String, Object> args) {
  final value = args['value'] as String;
  final salt = args['salt'] as List<int>;
  final iterations = args['iterations'] as int;
  final keyLength = args['keyLength'] as int;
  return _pbkdf2Sync(utf8.encode(value), salt, iterations, keyLength);
}

/// PBKDF2-HMAC-SHA256 (RFC 8018). Sinkron; dijalankan via compute().
List<int> _pbkdf2Sync(
  List<int> password,
  List<int> salt,
  int iterations,
  int keyLength,
) {
  final hmac = Hmac(sha256, password);
  const hLen = 32;
  final blockCount = (keyLength + hLen - 1) ~/ hLen;
  final result = <int>[];
  for (var block = 1; block <= blockCount; block++) {
    final saltBlock = <int>[
      ...salt,
      (block >> 24) & 0xff,
      (block >> 16) & 0xff,
      (block >> 8) & 0xff,
      block & 0xff,
    ];
    var u = hmac.convert(saltBlock).bytes;
    final t = List<int>.from(u);
    for (var i = 1; i < iterations; i++) {
      u = hmac.convert(u).bytes;
      for (var j = 0; j < hLen; j++) {
        t[j] ^= u[j];
      }
    }
    result.addAll(t);
  }
  return result.sublist(0, keyLength);
}
