/// Aturan kekuatan PIN aplikasi.
///
/// Dipisah dari Flutter supaya aturannya bisa diuji sebagai fungsi murni
/// (lihat `test/pin_policy_test.dart`).
///
/// Kebijakan:
/// - Panjang tetap 6 digit (sama dengan backup code).
/// - Hanya boleh berisi angka.
/// - Ditolak kalau polanya mudah ditebak: semua digit sama (mis. `111111`)
///   atau berurutan naik/turun (mis. `123456`, `654321`).
///
/// PIN lama milik user yang sebelumnya hanya 4 digit TETAP bisa dipakai untuk
/// membuka aplikasi - aturan ini hanya berlaku saat membuat PIN baru.
library;

/// Dilempar ketika PIN baru tidak memenuhi [PinPolicy].
class PinPolicyException implements Exception {
  /// Pesan error siap tampil ke user.
  final String message;

  const PinPolicyException(this.message);

  @override
  String toString() => message;
}

class PinPolicy {
  /// Panjang minimum PIN baru.
  static const int minLength = 6;

  /// Panjang maksimum PIN baru.
  static const int maxLength = 6;

  /// Apakah panjang PIN berada dalam rentang yang diperbolehkan?
  static bool isValidLength(String pin) =>
      pin.length >= minLength && pin.length <= maxLength;

  /// Apakah PIN hanya berisi angka?
  static bool isNumeric(String pin) =>
      pin.isNotEmpty && RegExp(r'^[0-9]+$').hasMatch(pin);

  /// Apakah PIN terlalu mudah ditebak?
  ///
  ///true untuk semua digit sama dan untuk deret berurutan naik/turun.
  /// PIN yang terlalu pendek tidak dianggap "lemah", melainkan tidak valid.
  static bool isWeak(String pin) {
    if (pin.length < 4) return false;
    if (!isNumeric(pin)) return false;
    if (_allDigitsSame(pin)) return true;
    return _isSequential(pin);
  }

  /// Apakah PIN ini boleh dipakai?
  static bool isValid(String pin) =>
      isNumeric(pin) && isValidLength(pin) && !isWeak(pin);

  /// Pesan error untuk PIN yang ditolak, atau `null` kalau PIN valid.
  static String? validate(String pin) {
    if (!isNumeric(pin)) return 'PIN harus hanya berisi angka';
    if (!isValidLength(pin)) {
      return 'PIN harus $maxLength digit';
    }
    if (isWeak(pin)) {
      return 'PIN terlalu mudah ditebak - hindari angka berurutan atau digit yang sama';
    }
    return null;
  }

  /// Semua digit sama, mis. `111111`.
  static bool _allDigitsSame(String pin) {
    final first = pin[0];
    for (var i = 1; i < pin.length; i++) {
      if (pin[i] != first) return false;
    }
    return true;
  }

  /// Deret digit berurutan naik (`123456`, `890123`) atau turun
  /// (`654321`, `210987`) pada siklus digit 0-9.
  static bool _isSequential(String pin) {
    var ascending = true;
    var descending = true;
    for (var i = 1; i < pin.length; i++) {
      final prev = pin.codeUnitAt(i - 1) - 0x30;
      final cur = pin.codeUnitAt(i) - 0x30;
      final diff = (cur - prev + 10) % 10;
      if (diff != 1) ascending = false;
      if (diff != 9) descending = false;
    }
    return ascending || descending;
  }
}
