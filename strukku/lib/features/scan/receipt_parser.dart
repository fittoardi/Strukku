class ParsedReceiptItem {
  const ParsedReceiptItem({
    required this.nama,
    required this.qty,
    required this.hargaSatuan,
    required this.subtotal,
  });

  final String nama;
  final int qty;
  final int hargaSatuan;
  final int subtotal;
}

class ParsedReceipt {
  const ParsedReceipt({
    this.namaToko,
    this.tanggal,
    this.items = const [],
    this.subtotal = 0,
    this.pajak = 0,
    this.diskon = 0,
    this.total = 0,
    this.confidence = 0,
    this.catatanParser,
  });

  final String? namaToko;
  final DateTime? tanggal;
  final List<ParsedReceiptItem> items;
  final int subtotal;
  final int pajak;
  final int diskon;
  final int total;
  final double confidence;
  final String? catatanParser;

  bool get totalValid =>
      total > 0 &&
      (items.isEmpty || (items.fold<int>(0, (sum, item) => sum + item.subtotal) + pajak - diskon - total).abs() <= 100);
}

class ReceiptParser {
  static ParsedReceipt parse(String text, {DateTime? now}) {
    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final today = now ?? DateTime.now();
    final total = _findAmount(lines, [r'grand\s*total', r'total', r'jumlah', r'bayar']);
    final subtotal = _findAmount(lines, [r'subtotal', r'sub\s*total']) ?? 0;
    final pajak = _findAmount(lines, [r'pajak', r'ppn', r'tax']) ?? 0;
    final diskon = _findAmount(lines, [r'diskon', r'discount']) ?? 0;
    final date = _findDate(text, today);
    final items = _findItems(lines);
    final store = lines.isEmpty ? null : lines.first;
    final confidence = _confidence(total, date, store, items);

    return ParsedReceipt(
      namaToko: store,
      tanggal: date,
      items: items,
      subtotal: subtotal,
      pajak: pajak,
      diskon: diskon,
      total: total ?? 0,
      confidence: confidence,
      catatanParser: total == null || date == null ? 'Periksa total dan tanggal.' : null,
    );
  }

  static int? _findAmount(List<String> lines, List<String> labels) {
    for (final line in lines.reversed) {
      if (!labels.any((label) => RegExp(label, caseSensitive: false).hasMatch(line))) continue;
      final matches = RegExp(r'(?:Rp\.?\s*)?([0-9][0-9.\s,]*)', caseSensitive: false).allMatches(line);
      if (matches.isEmpty) continue;
      final value = _amount(matches.last.group(1)!);
      if (value != null && value > 0) return value;
    }
    return null;
  }

  static List<ParsedReceiptItem> _findItems(List<String> lines) {
    final items = <ParsedReceiptItem>[];
    for (final line in lines) {
      final match = RegExp(r'^(.+?)\s+(\d+)\s*[xX]\s*(?:Rp\.?\s*)?([\d.,]+)\s+(?:Rp\.?\s*)?([\d.,]+)$').firstMatch(line);
      if (match == null) continue;
      final qty = int.tryParse(match.group(2)!);
      final unit = _amount(match.group(3)!);
      final subtotal = _amount(match.group(4)!);
      if (qty != null && unit != null && subtotal != null && qty > 0) {
        items.add(ParsedReceiptItem(nama: match.group(1)!.trim(), qty: qty, hargaSatuan: unit, subtotal: subtotal));
      }
    }
    return items;
  }

  static DateTime? _findDate(String text, DateTime today) {
    final match = RegExp(r'\b(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})\b').firstMatch(text);
    if (match == null) return null;
    var year = int.parse(match.group(3)!);
    if (year < 100) year += 2000;
    final value = DateTime(year, int.parse(match.group(2)!), int.parse(match.group(1)!));
    return value.isAfter(today) ? null : value;
  }

  static int? _amount(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  static double _confidence(int? total, DateTime? date, String? store, List<ParsedReceiptItem> items) {
    var score = 0.0;
    if (store != null) score += .2;
    if (date != null) score += .3;
    if (total != null) score += .4;
    if (items.isNotEmpty) score += .1;
    return score;
  }
}
