import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Ergebnis einer OCR-Erkennung inklusive Qualitätseinschätzung,
/// damit die App bei schlecht lesbaren Bildern nichts erfindet,
/// sondern ehrlich meldet, dass der Text nicht eindeutig erkannt wurde.
class OcrResult {
  final String text;
  final bool isReliable;
  final int blockCount;
  final double averageConfidenceHint; // grober Heuristikwert 0..1

  OcrResult({
    required this.text,
    required this.isReliable,
    required this.blockCount,
    required this.averageConfidenceHint,
  });

  static const unreadableMessage =
      'Der Text konnte nicht eindeutig erkannt werden. Bitte lade ein schärferes Bild hoch.';
}

class OcrService {
  final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Führt die Texterkennung durch und schätzt heuristisch ab, ob das
  /// Ergebnis vertrauenswürdig genug ist, um daran weiterzuarbeiten
  /// (Zusammenfassen, Aufgaben lösen, etc.).
  Future<OcrResult> recognize(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognized = await _recognizer.processImage(inputImage);

    final text = recognized.text.trim();
    final blockCount = recognized.blocks.length;

    // Heuristik: sehr wenig erkannter Text, sehr viele extrem kurze
    // Zeilen oder ein hoher Anteil an Sonderzeichen/Ziffern-Kauderwelsch
    // deuten auf Unschärfe oder schlechte Lesbarkeit hin.
    final lines = recognized.blocks.expand((b) => b.lines).toList();
    final shortLineRatio =
        lines.isEmpty ? 1.0 : lines.where((l) => l.text.trim().length < 2).length / lines.length;

    final looksEmpty = text.length < 3;
    final looksNoisy = shortLineRatio > 0.5 && lines.length > 3;

    final isReliable = !looksEmpty && !looksNoisy;
    final confidenceHint = looksEmpty ? 0.0 : (looksNoisy ? 0.35 : 0.85);

    return OcrResult(
      text: text,
      isReliable: isReliable,
      blockCount: blockCount,
      averageConfidenceHint: confidenceHint,
    );
  }

  void dispose() {
    _recognizer.close();
  }
}
