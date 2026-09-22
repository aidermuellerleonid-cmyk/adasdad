import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_provider.dart';

/// Beispiel-Adapter für OpenAI, zeigt wie leicht ein neuer Anbieter
/// hinzugefügt werden kann: einfach `AiProvider` implementieren.
class OpenAiProvider implements AiProvider {
  final String apiKey;
  final String model;

  OpenAiProvider({required this.apiKey, this.model = 'gpt-4o-mini'});

  @override
  String get name => 'OpenAI';

  @override
  Future<String> generateText(String prompt) async {
    if (apiKey.trim().isEmpty) throw MissingApiKeyException();
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'user', 'content': prompt}
      ],
      'temperature': 0.3,
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
      'model': model,
      'messages': [
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': prompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image'}
            }
          ]
        }
      ],
      'temperature': 0.2,
    });
    return _send(body);
  }

  Future<String> _send(String body) async {
    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse('https://api.openai.com/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 45));
    } catch (e) {
      throw AiRequestException('Keine Verbindung zur KI möglich: $e');
    }

    if (response.statusCode != 200) {
      throw AiRequestException('KI-Anfrage fehlgeschlagen (${response.statusCode}): ${response.body}');
    }

    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return (decoded['choices'][0]['message']['content'] as String).trim();
  }
}
