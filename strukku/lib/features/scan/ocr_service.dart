import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> recognize(String imagePath) async {
    final result = await _recognizer.processImage(InputImage.fromFilePath(imagePath));
    return result.text;
  }

  Future<void> dispose() => _recognizer.close();
}
