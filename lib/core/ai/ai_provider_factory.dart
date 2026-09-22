import 'package:shared_preferences/shared_preferences.dart';
import 'ai_provider.dart';
import 'gemini_provider.dart';
import 'openai_provider.dart';

enum AiProviderType { gemini, openAi }

/// Erzeugt den aktuell in den Einstellungen ausgewählten AiProvider.
/// Das ist der einzige Ort, an dem entschieden wird, welches KI-Modell
/// tatsächlich verwendet wird – ein Wechsel des Modells bedeutet also
/// nur eine Änderung hier bzw. in den Einstellungen der App.
class AiProviderFactory {
  static const _keyProvider = 'ai_provider_type';
  static const _keyGeminiKey = 'gemini_api_key';
  static const _keyOpenAiKey = 'openai_api_key';

  static Future<AiProvider> current() async {
    final prefs = await SharedPreferences.getInstance();
    final typeName = prefs.getString(_keyProvider) ?? AiProviderType.gemini.name;

    switch (typeName) {
      case 'openAi':
        return OpenAiProvider(apiKey: prefs.getString(_keyOpenAiKey) ?? '');
      case 'gemini':
      default:
        return GeminiProvider(apiKey: prefs.getString(_keyGeminiKey) ?? '');
    }
  }

  static Future<void> setProviderType(AiProviderType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProvider, type.name);
  }

  static Future<AiProviderType> getProviderType() async {
    final prefs = await SharedPreferences.getInstance();
    final typeName = prefs.getString(_keyProvider) ?? AiProviderType.gemini.name;
    return AiProviderType.values.firstWhere((e) => e.name == typeName,
        orElse: () => AiProviderType.gemini);
  }

  static Future<void> setApiKey(AiProviderType type, String key) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case AiProviderType.gemini:
        await prefs.setString(_keyGeminiKey, key);
        break;
      case AiProviderType.openAi:
        await prefs.setString(_keyOpenAiKey, key);
        break;
    }
  }

  static Future<String> getApiKey(AiProviderType type) async {
    final prefs = await SharedPreferences.getInstance();
    switch (type) {
      case AiProviderType.gemini:
        return prefs.getString(_keyGeminiKey) ?? '';
      case AiProviderType.openAi:
        return prefs.getString(_keyOpenAiKey) ?? '';
    }
  }
}
