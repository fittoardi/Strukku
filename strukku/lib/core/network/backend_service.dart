import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/scan/receipt_parser.dart';

class BackendService {
  final String baseUrl;

  BackendService({this.baseUrl = 'http://10.0.2.2:8000'});

  Future<ParsedReceipt> parseReceipt(String ocrText) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/parse-receipt'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ocr_text': ocrText}),
      ).timeout(const Duration(seconds: 25));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapToParsedReceipt(data);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback ke parser lokal jika gagal
      return ReceiptParser.parse(ocrText);
    }
  }

  ParsedReceipt _mapToParsedReceipt(Map<String, dynamic> json) {
    return ParsedReceipt(
      namaToko: json['nama_toko'],
      tanggal: json['tanggal'] != null ? DateTime.tryParse(json['tanggal']) : null,
      items: (json['items'] as List).map((i) => ParsedReceiptItem(
        nama: i['nama'],
        qty: i['qty'] ?? 1,
        hargaSatuan: i['harga_satuan'] ?? 0,
        subtotal: i['subtotal'] ?? 0,
      )).toList(),
      subtotal: json['subtotal'] ?? 0,
      pajak: json['pajak'] ?? 0,
      diskon: json['diskon'] ?? 0,
      total: json['total'] ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      catatanParser: json['catatan_parser'],
    );
  }
}
