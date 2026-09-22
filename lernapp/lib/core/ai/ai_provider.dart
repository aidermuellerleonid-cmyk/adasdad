/// Abstraktes Interface für jede KI-Anbindung.
///
/// WICHTIG: Wenn später ein anderes KI-Modell verwendet werden soll
/// (z. B. OpenAI statt Gemini), muss NUR eine neue Klasse geschrieben
/// werden, die dieses Interface implementiert. Der Rest der App bleibt
/// unverändert, weil überall nur gegen `AiProvider` programmiert wird.
abstract class AiProvider {
  /// Name des Anbieters, z. B. "Google Gemini".
  String get name;

  /// Sendet einen reinen Text-Prompt und gibt die Antwort als String zurück.
  Future<String> generateText(String prompt);

  /// Sendet einen Prompt zusammen mit einem Bild (Base64-kodiert) und
  /// gibt die Antwort als String zurück. Wird für die Bildanalyse
  /// (Erkennen, was auf dem Bild zu sehen ist) verwendet, zusätzlich
  /// zur lokalen OCR-Texterkennung.
  Future<String> generateFromImage({
    required String prompt,
    required String base64Image,
    required String mimeType,
  });
}

/// Wird geworfen, wenn kein API-Schlüssel hinterlegt ist.
class MissingApiKeyException implements Exception {
  final String message;
  MissingApiKeyException([this.message = 'Kein API-Schlüssel hinterlegt. Bitte in den Einstellungen eintragen.']);

  @override
  String toString() => message;
}

/// Wird geworfen, wenn die KI-Anfrage fehlschlägt (Netzwerk, Server, etc.).
class AiRequestException implements Exception {
  final String message;
  AiRequestException(this.message);

  @override
  String toString() => message;
}
