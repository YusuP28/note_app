import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/note_provider.dart';

/// Fungsi purge yang bisa di-inject (default: [NoteProvider.purgeOldTrash]).
typedef TrashPurgeCallback = Future<void> Function(int days);

/// Auto-purge sampah: catatan di sampah yang sudah lebih tua dari
/// [days] hari dihapus permanen secara otomatis saat aplikasi dibuka.
///
/// Ini menutup kesenjangan spec: README mengklaim "Auto-purge - sampah >
/// 30 hari otomatis dibersihkan", sebelumnya [NoteProvider.purgeOldTrash]
/// hanya bisa dipanggil manual dari Settings.
///
/// Timestamp terakhir purge disimpan di SharedPreferences (key
/// [lastRunKey]) supaya purge tidak dijalankan lebih dari sekali sehari.
class TrashPurgeService {
  /// Key SharedPreferences untuk menyimpan waktu purge terakhir.
  static const String lastRunKey = 'trash_purge_last_run';

  /// Jarak minimum antar dua kali purge (hari).
  static const int minIntervalDays = 1;

  final TrashPurgeCallback _purge;

  /// [purge] dipakai untuk testing; kalau null memakai
  /// [NoteProvider.purgeOldTrash].
  TrashPurgeService({TrashPurgeCallback? purge})
      : _purge = purge ?? _purgeDefault;

  static Future<void> _purgeDefault(int days) async {
    await NoteProvider().purgeOldTrash(days: days);
  }

  /// Apakah purge perlu dijalankan sekarang?
  ///
  /// - `lastRun == null` (belum pernah jalan) → selalu jalan.
  /// - Selain itu jalan kalau sudah lewat [minIntervalDays] (1 hari).
  ///
  /// [days] adalah ambang usia isi sampah (mis. 30 hari) - tidak memengaruhi
  /// penjadwalan, hanya dipakai saat purge benar-benar dijalankan.
  static Future<bool> shouldRun({
    required DateTime? lastRun,
    required int days,
    required DateTime now,
  }) async {
    if (lastRun == null) return true;
    return now.difference(lastRun).inDays >= minIntervalDays;
  }

  /// Jalankan purge kalau sudah waktunya, lalu simpan waktu purge terakhir.
  ///
  /// Kalau purge gagal, exception diteruskan dan timestamp TIDAK disimpan,
  /// supaya purge dicoba lagi di pembukaan aplikasi berikutnya.
  Future<void> runIfDue({int days = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRunMs = prefs.getInt(lastRunKey) ?? 0;
    final lastRun = lastRunMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastRunMs)
        : null;
    final now = DateTime.now();

    final jalan = await shouldRun(lastRun: lastRun, days: days, now: now);
    if (!jalan) {
      debugPrint('Auto-purge: belum waktunya');
      return;
    }

    await _purge(days);
    await prefs.setInt(lastRunKey, now.millisecondsSinceEpoch);
    debugPrint('Auto-purge: sampah > $days hari dibersihkan');
  }
}
