import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// Google-Gemini-Adapter. Nutzt das kostenlose Kontingent der
/// Gemini-API (generativelanguage.googleapis.com).
///
/// Ein API-Schlüssel wird kostenlos unter https://aistudio.google.com/apikey
/// erstellt und in den App-Einstellungen hinterlegt.
class GeminiProvider implements AiProvider {
  final String apiKey;
  final String model;

  GeminiProvider({required this.apiKey, this.model = 'gemini-3.8-flash'});

  @override
  String get name => 'Google Gemini';

  Uri _endpoint() => Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

  @override
  Future<String> generateText(String prompt) async {
    if (apiKey.trim().isEmpty) throw MissingApiKeyException();

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.3,
      }
    });

    return _send(body);
  }

  @override
  Future<String> generateFromImage({
    required String prompt,
    required String base64Image,
    required String mimeType,
  }) async {
    if (apiKey.trim().isEmpty) throw MissingApiKeyException();

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
      }
    });

    return _send(body);
  }

  Future<String> _send(String body) async {
    http.Response response;
    try {
      response = await http
          .post(_endpoint(), headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw AiRequestException('Keine Verbindung zur KI möglich: $e');
    }

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        detail = decoded['error']?['message']?.toString() ?? response.body;
      } catch (_) {}
      throw AiRequestException('KI-Anfrage fehlgeschlagen (${response.statusCode}): $detail');
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw AiRequestException('Die KI hat keine Antwort geliefert.');
      }
      final parts = candidates[0]['content']?['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        throw AiRequestException('Die KI hat keine Antwort geliefert.');
      }
      final buffer = StringBuffer();
      for (final p in parts) {
        if (p['text'] != null) buffer.write(p['text']);
      }
      return buffer.toString().trim();
    } catch (e) {
      if (e is AiRequestException) rethrow;
      throw AiRequestException('Antwort der KI konnte nicht gelesen werden: $e');
    }
  }
}
