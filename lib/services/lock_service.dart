import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';

/// Service untuk PIN lock aplikasi.
/// - PIN disimpan sebagai SHA-256 hash
/// - Hint + backup code (6 digit)
/// - Support fingerprint (local_auth)
class LockService {
  static final LockService _i = LockService._();
  factory LockService() => _i;
  LockService._();

  static const _kPinHash = 'lock_pin_hash';
  static const _kPinHint = 'lock_pin_hint';
  static const _kBackupCode = 'lock_backup_code';
  static const _kEnabled = 'lock_enabled';
  static const _kFingerprint = 'lock_fingerprint';

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

  Future<String?> getBackupCode() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kBackupCode);
  }

  // ==== SET PIN ====
  Future<String> setPin(String pin, {String? hint}) async {
    final p = await SharedPreferences.getInstance();
    final hash = _hash(pin);
    final code = _generateBackupCode();

    await p.setString(_kPinHash, hash);
    await p.setString(_kBackupCode, code);
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
    await p.setBool(_kEnabled, false);
    await p.setBool(_kFingerprint, false);
  }

  Future<void> setFingerprint(bool enabled) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kFingerprint, enabled);
  }

  // ==== VERIFY ====
  Future<bool> verifyPin(String pin) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_kPinHash);
    if (stored == null) return false;
    return stored == _hash(pin);
  }

  Future<bool> verifyBackupCode(String code) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString(_kBackupCode);
    if (stored == null) return false;
    return stored.trim() == code.trim();
  }

  /// Reset PIN pakai backup code.
  Future<bool> resetWithBackupCode(String code, String newPin, {String? hint}) async {
    if (!await verifyBackupCode(code)) return false;
    await setPin(newPin, hint: hint);
    return true;
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

  Future<bool> authenticateBiometric() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Verifikasi untuk membuka catatan terkunci',
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
  String _hash(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  String _generateBackupCode() {
    final r = Random.secure();
    final code = List.generate(6, (_) => r.nextInt(10)).join();
    return code;
  }
}
