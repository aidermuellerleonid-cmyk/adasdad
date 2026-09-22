import 'package:flutter/material.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/ai/prompts.dart';
import '../summary/result_screen.dart';

/// Zeigt die Lösung einer Matheaufgabe inklusive vollständigem Rechenweg.
/// Nutzt den generischen ResultScreen, aber mit einem speziellen Prompt,
/// der die KI anweist, ihr Ergebnis vor der Ausgabe selbst zu überprüfen.
class MathResultScreen extends StatelessWidget {
  final String sourceText;

  const MathResultScreen({super.key, required this.sourceText});

  @override
  Widget build(BuildContext context) {
    return ResultScreen(
      title: 'Rechenweg & Lösung',
      sourceText: sourceText,
      entryTypeName: 'mathe',
      generator: (t) async {
        final provider = await AiProviderFactory.current();
        return provider.generateText(Prompts.solveMath(t));
      },
    );
  }
}
