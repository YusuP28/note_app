/// Guard path media - mencegah path traversal saat restore backup.
///
/// Nilai path pada backup JSON dikontrol penyerang (file backup bisa dikirim
/// korban), sehingga harus divalidasi sebelum dipakai.
library;

import 'package:path/path.dart' as p;

/// Exception kalau path di luar root yang diizinkan.
class MediaPathException implements Exception {
  final String message;

  const MediaPathException(this.message);

  @override
  String toString() => 'MediaPathException: $message';
}

/// Folder penyimpan attachment di dalam backup.
const String attachmentsFolder = 'attachments';

/// Ubah path absolut media menjadi path relatif (untuk storage di backup).
///
/// Returns null kalau path bukan milik [attachmentsRoot].
String? toRelativeMediaPath(String? value, String attachmentsRoot) {
  if (value == null || value.isEmpty) return value;
  final normalized = p.normalize(value);
  if (normalized == attachmentsRoot ||
      p.isWithin(attachmentsRoot, normalized)) {
    final relative = p
        .relative(normalized, from: attachmentsRoot)
        .replaceAll(p.separator, '/');
    return '$attachmentsFolder/$relative';
  }
  return value;
}

/// Ubah path relatif media dari backup menjadi path absolut.
///
/// Melempar [MediaPathException] kalau path mencoba keluar dari
/// [attachmentsRoot] (path traversal).
///
/// Bandingkan dengan implementasi lama di backup_service.dart yang memakai
/// `p.join` tanpa validasi - `p.join` menormalisasi `../` sehingga path bisa
/// keluar dari sandbox.
String? toAbsoluteMediaPath(String? value, String attachmentsRoot) {
  if (value == null || value.isEmpty) return value;
  final normalized = value.replaceAll('\\', '/');
  if (normalized == attachmentsFolder) return attachmentsRoot;
  if (!normalized.startsWith('$attachmentsFolder/')) return value;

  final relative = normalized.substring(attachmentsFolder.length + 1);
  final resolved = p.normalize(p.join(attachmentsRoot, relative));

  if (resolved != attachmentsRoot && !p.isWithin(attachmentsRoot, resolved)) {
    throw MediaPathException(
      'Path media di luar folder attachment ditolak: $value',
    );
  }
  return resolved;
}
