import 'package:flutter/material.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AiProviderType _type = AiProviderType.gemini;
  final _keyController = TextEditingController();
  bool _loading = true;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final type = await AiProviderFactory.getProviderType();
    final key = await AiProviderFactory.getApiKey(type);
    setState(() {
      _type = type;
      _keyController.text = key;
      _loading = false;
    });
  }

  Future<void> _save() async {
    await AiProviderFactory.setProviderType(_type);
    await AiProviderFactory.setApiKey(_type, _keyController.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const Text('KI-Anbieter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        RadioListTile<AiProviderType>(
                          title: const Text('Google Gemini'),
                          subtitle: const Text('Kostenloses Kontingent verfügbar'),
                          value: AiProviderType.gemini,
                          groupValue: _type,
                          onChanged: (v) async {
                            setState(() => _type = v!);
                            final key = await AiProviderFactory.getApiKey(_type);
                            _keyController.text = key;
                          },
                        ),
                        RadioListTile<AiProviderType>(
                          title: const Text('OpenAI'),
                          value: AiProviderType.openAi,
                          groupValue: _type,
                          onChanged: (v) async {
                            setState(() => _type = v!);
                            final key = await AiProviderFactory.getApiKey(_type);
                            _keyController.text = key;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('API-Schlüssel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: 'API-Schlüssel einfügen'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _type == AiProviderType.gemini
                        ? 'Kostenlos erstellen unter: aistudio.google.com/apikey'
                        : 'Erstellen unter: platform.openai.com/api-keys',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _save,
                    child: const Text('Speichern'),
                  ),
                  if (_saved)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('Gespeichert ✓', style: TextStyle(color: AppTheme.success)),
                    ),
                ],
              ),
      ),
    );
  }
}
