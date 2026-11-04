import 'package:intl/intl.dart';

/// Format integer rupiah jadi "Rp 12.500"
String formatRupiah(int amount) {
  final formatter = NumberFormat('#,###', 'id_ID');
  return 'Rp ${formatter.format(amount)}';
}

/// Format tanggal ke "12 Okt 2026"
String formatTanggal(DateTime date) {
  return DateFormat('d MMM yyyy', 'id_ID').format(date);
}

/// Format tanggal ke "Senin, 12 Okt 2026"
String formatTanggalLengkap(DateTime date) {
  return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(date);
}

/// Format tanggal ke "12 Okt"
String formatTanggalPendek(DateTime date) {
  return DateFormat('d MMM', 'id_ID').format(date);
}
