import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai/ai_provider.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/ai/prompts.dart';
import '../../core/db/app_database.dart';
import '../../core/db/models.dart';
import '../../core/theme.dart';
import '../summary/result_screen.dart';

enum LearnMode { lernzettel, quiz }

/// Erzeugt entweder einen Lernzettel (einfacher Text, nutzt ResultScreen)
/// oder ein interaktives Quiz (eigene Anzeige mit auswählbaren Antworten).
class LearnResultScreen extends StatelessWidget {
  final String sourceText;
  final LearnMode mode;

  const LearnResultScreen({super.key, required this.sourceText, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (mode == LearnMode.lernzettel) {
      return ResultScreen(
        title: 'Lernzettel',
        sourceText: sourceText,
        entryTypeName: 'lernzettel',
        generator: (t) async {
          final provider = await AiProviderFactory.current();
          return provider.generateText(Prompts.lernzettel(t));
        },
      );
    }
    return QuizScreen(sourceText: sourceText);
  }
}

class QuizQuestion {
  final String question;
  final List<String> options; // "A) ..." bereits ohne Präfix, gespeichert als Text
  final String correctLetter;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctLetter,
    required this.explanation,
  });
}

class QuizScreen extends StatefulWidget {
  final String sourceText;
  const QuizScreen({super.key, required this.sourceText});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  bool _loading = true;
  String? _error;
  List<QuizQuestion> _questions = [];
  String _rawText = '';
  final Map<int, String> _answers = {};

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final provider = await AiProviderFactory.current();
      final text = await provider.generateText(Prompts.quiz(widget.sourceText));
      final parsed = _parseQuiz(text);
      setState(() {
        _rawText = text;
        _questions = parsed;
        _loading = false;
      });
      await AppDatabase.instance.insertHistoryEntry(HistoryEntry(
        id: const Uuid().v4(),
        type: EntryType.quiz,
        title: 'Quiz',
        content: text,
        createdAt: DateTime.now(),
      ));
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

  List<QuizQuestion> _parseQuiz(String text) {
    final blocks = text.split(RegExp(r'\n(?=Frage\s*\d*:)'));
    final result = <QuizQuestion>[];
    for (final block in blocks) {
      final lines = block.trim().split('\n').where((l) => l.trim().isNotEmpty).toList();
      if (lines.isEmpty) continue;
      final questionLine = lines.firstWhere((l) => l.startsWith('Frage'), orElse: () => '');
      if (questionLine.isEmpty) continue;
      final question = questionLine.replaceFirst(RegExp(r'^Frage\s*\d*:\s*'), '');
      final options = <String>[];
      String correct = '';
      String explanation = '';
      for (final l in lines) {
        if (RegExp(r'^[A-D]\)').hasMatch(l.trim())) {
          options.add(l.trim());
        } else if (l.trim().startsWith('Richtig:')) {
          correct = l.trim().replaceFirst('Richtig:', '').trim();
        } else if (l.trim().startsWith('Erklärung:')) {
          explanation = l.trim().replaceFirst('Erklärung:', '').trim();
        }
      }
      if (options.isNotEmpty && correct.isNotEmpty) {
        result.add(QuizQuestion(
          question: question,
          options: options,
          correctLetter: correct.replaceAll(')', '').trim(),
          explanation: explanation,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Quiz wird erstellt…'),
          ],
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

    if (_questions.isEmpty) {
      // Fallback: Falls das Parsen fehlschlägt, zeige den Rohtext an.
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(_rawText),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final q = _questions[index];
        final selected = _answers[index];
        final answered = selected != null;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${index + 1}. ${q.question}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 10),
                ...q.options.map((opt) {
                  final letter = opt.substring(0, 1);
                  final isCorrect = letter == q.correctLetter;
                  final isSelected = selected == letter;

                  Color? bg;
                  if (answered) {
                    if (isCorrect) {
                      bg = AppTheme.success.withOpacity(0.15);
                    } else if (isSelected) {
                      bg = AppTheme.error.withOpacity(0.12);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: answered
                          ? null
                          : () => setState(() => _answers[index] = letter),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: bg ?? Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(opt),
                      ),
                    ),
                  );
                }),
                if (answered) ...[
                  const SizedBox(height: 6),
                  Text(
                    selected == q.correctLetter ? 'Richtig!' : 'Leider falsch.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected == q.correctLetter ? AppTheme.success : AppTheme.error,
                    ),
                  ),
                  if (q.explanation.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(q.explanation, style: const TextStyle(color: Colors.black54)),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
