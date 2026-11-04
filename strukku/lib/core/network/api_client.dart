import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  static const String _baseUrl = 'https://<project>.supabase.co/functions/v1/parse-receipt';

  Future<Map<String, dynamic>> parseReceipt(String ocrText) async {
    const token = String.fromEnvironment('SUPABASE_ANON_KEY');
    final response = await http.Client().post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'ocr_text': ocrText}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Parse gagal: ${response.statusCode} ${response.body}');
  }
}
