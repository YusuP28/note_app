import 'package:intl/intl.dart';

class AppDate {
  static String short(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy', 'id_ID').format(d);
  }

  static String full(DateTime d) =>
      DateFormat('EEEE, dd MMMM yyyy • HH:mm', 'id_ID').format(d);
}
