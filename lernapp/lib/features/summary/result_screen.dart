import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai/ai_provider.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/db/app_database.dart';
import '../../core/db/models.dart';
import '../../core/theme.dart';

/// Zeigt eine KI-generierte Textantwort an (Zusammenfassung, Erklärung, ...).
/// Kümmert sich um: Laden, Fehlerbehandlung, Speichern im Verlauf,
/// Kopieren, Bearbeiten und Teilen.
class ResultScreen extends StatefulWidget {
  final String title;
  final String sourceText;
  final Future<String> Function(String sourceText) generator;
  final String entryTypeName;

  const ResultScreen({
    super.key,
    required this.title,
    required this.sourceText,
    required this.generator,
    required this.entryTypeName,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _loading = true;
  String? _error;
  String _resultText = '';
  bool _editing = false;
  late final TextEditingController _controller;
  String? _savedEntryId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final text = await widget.generator(widget.sourceText);
      setState(() {
        _resultText = text;
        _controller.text = text;
        _loading = false;
      });
      await _saveToHistory(text);
    } on MissingApiKeyException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } on AiRequestException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Unerwarteter Fehler: $e';
      });
    }
  }

  Future<void> _saveToHistory(String text) async {
    final id = const Uuid().v4();
    final type = EntryType.values.firstWhere((t) => t.name == widget.entryTypeName,
        orElse: () => EntryType.zusammenfassung);
    final entry = HistoryEntry(
      id: id,
      type: type,
      title: widget.title,
      content: text,
      createdAt: DateTime.now(),
    );
    await AppDatabase.instance.insertHistoryEntry(entry);
    _savedEntryId = id;
  }

  Future<void> _updateSavedContent(String newText) async {
    if (_savedEntryId != null) {
      await AppDatabase.instance.updateHistoryEntryContent(_savedEntryId!, newText);
    }
  }

  Future<void> _deleteFromHistory() async {
    if (_savedEntryId != null) {
      await AppDatabase.instance.deleteHistoryEntry(_savedEntryId!);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (!_loading && _error == null) ...[
            IconButton(
              tooltip: 'Kopieren',
              icon: const Icon(Icons.copy_outlined),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _controller.text));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('In Zwischenablage kopiert')));
              },
            ),
            IconButton(
              tooltip: 'Teilen',
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(_controller.text),
            ),
            IconButton(
              tooltip: _editing ? 'Speichern' : 'Bearbeiten',
              icon: Icon(_editing ? Icons.check : Icons.edit_outlined),
              onPressed: () async {
                if (_editing) {
                  setState(() {
                    _resultText = _controller.text;
                    _editing = false;
                  });
                  await _updateSavedContent(_resultText);
                } else {
                  setState(() => _editing = true);
                }
              },
            ),
            IconButton(
              tooltip: 'Löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteFromHistory,
            ),
          ],
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Die KI arbeitet daran…'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.error, size: 40),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _generate, child: const Text('Erneut versuchen')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: _editing
          ? TextField(
              controller: _controller,
              maxLines: null,
              style: const TextStyle(fontSize: 15, height: 1.5),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            )
          : Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SelectableText(
                  _controller.text,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
              ),
            ),
    );
  }
}

/// Zwischenscreen für "Zusammenfassen": Auswahl der Art der Zusammenfassung.
class SummaryOptionsScreen extends StatelessWidget {
  final String sourceText;

  const SummaryOptionsScreen({super.key, required this.sourceText});

  @override
  Widget build(BuildContext context) {
    final options = [
      'Kurz',
      'Normal',
      'Ausführlich',
      'Stichpunkte',
      'Lernzettel-Stil',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Art der Zusammenfassung')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final art = options[index];
            return Card(
              child: ListTile(
                title: Text(art, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ResultScreen(
                        title: 'Zusammenfassung ($art)',
                        sourceText: sourceText,
                        generator: (t) => _buildSummary(t, art),
                        entryTypeName: 'zusammenfassung',
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

Future<String> _buildSummary(String text, String art) async {
  final provider = await AiProviderFactory.current();
  return provider.generateText(_summaryPrompt(text, art));
}

String _summaryPrompt(String text, String art) => '''
Du bist eine Lernhilfe für Schüler. Fasse den folgenden Text als "$art" zusammen.
Arbeite die wichtigsten Informationen klar heraus und stelle sie übersichtlich dar.
Verwende einfache, verständliche Sprache. Erfinde keine Informationen, die nicht im Text stehen.

Text:
"""
$text
"""
''';
