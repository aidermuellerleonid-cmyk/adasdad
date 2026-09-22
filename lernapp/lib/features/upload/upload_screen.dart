import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/ai/prompts.dart';
import '../../core/ocr/ocr_service.dart';
import '../../core/theme.dart';
import '../summary/result_screen.dart';
import '../math/math_result_screen.dart';
import '../learn/learn_result_screen.dart';
import '../chat/chat_screen.dart';
import 'material_state.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _picker = ImagePicker();
  final _ocr = OcrService();
  bool _processing = false;
  String? _statusText;
  String? _errorText;

  @override
  void dispose() {
    _ocr.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final xfile = await _picker.pickImage(source: source, imageQuality: 90);
    if (xfile == null) return;
    await _processImage(File(xfile.path));
  }

  Future<void> _processImage(File file) async {
    setState(() {
      _processing = true;
      _errorText = null;
      _statusText = 'Bild wird erkannt (OCR)…';
    });

    try {
      final ocrResult = await _ocr.recognize(file);

      String? description;
      if (ocrResult.isReliable) {
        setState(() => _statusText = 'Bildinhalt wird analysiert…');
        try {
          final provider = await AiProviderFactory.current();
          final bytes = await file.readAsBytes();
          final base64 = _bytesToBase64(bytes);
          description = await provider.generateFromImage(
            prompt: Prompts.imageAnalysis(),
            base64Image: base64,
            mimeType: 'image/jpeg',
          );
        } catch (_) {
          // Bildbeschreibung ist optional – bei Fehler machen wir ohne weiter.
          description = null;
        }
      }

      if (!mounted) return;
      final session = context.read<MaterialSessionState>();
      session.addMaterial(UploadedMaterial(
        imageFile: file,
        recognizedText: ocrResult.text,
        ocrReliable: ocrResult.isReliable,
        imageDescription: description,
      ));

      setState(() {
        _processing = false;
        _statusText = null;
      });

      if (!ocrResult.isReliable) {
        _showUnreadableWarning();
      }
    } catch (e) {
      setState(() {
        _processing = false;
        _statusText = null;
        _errorText = 'Bei der Verarbeitung ist ein Fehler aufgetreten: $e';
      });
    }
  }

  String _bytesToBase64(List<int> bytes) {
    return base64Encode(bytes);
  }

  void _showUnreadableWarning() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bild nicht eindeutig lesbar'),
        content: const Text(OcrResult.unreadableMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    // Mehrere Bilder aus der Galerie auswählen.
    final files = await _picker.pickMultiImage(imageQuality: 90);
    for (final f in files) {
      await _processImage(File(f.path));
    }
  }

  void _goToAction(_Action action) {
    final session = context.read<MaterialSessionState>();
    final text = session.combinedText;

    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Es wurde kein lesbarer Text erkannt.')),
      );
      return;
    }

    switch (action) {
      case _Action.zusammenfassen:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SummaryOptionsScreen(sourceText: text)),
        );
        break;
      case _Action.mathe:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MathResultScreen(sourceText: text)),
        );
        break;
      case _Action.erklaeren:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              title: 'Erklärung',
              sourceText: text,
              generator: (t) async {
                final provider = await AiProviderFactory.current();
                return provider.generateText(Prompts.explain(t));
              },
              entryTypeName: 'erklaerung',
            ),
          ),
        );
        break;
      case _Action.lernzettel:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LearnResultScreen(sourceText: text, mode: LearnMode.lernzettel)),
        );
        break;
      case _Action.quiz:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LearnResultScreen(sourceText: text, mode: LearnMode.quiz)),
        );
        break;
      case _Action.chat:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChatScreen(material: text)),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<MaterialSessionState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lernhilfe', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (session.hasMaterial)
            IconButton(
              tooltip: 'Material löschen',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => session.clear(),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _uploadCard(),
              if (_processing) ...[
                const SizedBox(height: 16),
                _processingCard(),
              ],
              if (_errorText != null) ...[
                const SizedBox(height: 16),
                _errorCard(_errorText!),
              ],
              if (session.hasMaterial) ...[
                const SizedBox(height: 20),
                _materialSummaryCard(session),
                const SizedBox(height: 20),
                const Text(
                  'Was möchtest du damit machen?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _actionGrid(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, size: 48, color: AppTheme.primary),
            const SizedBox(height: 12),
            const Text(
              'Lade ein Foto deiner Aufgabe oder deines Textes hoch',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _processing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galerie'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _processing ? null : _pickFiles,
              icon: const Icon(Icons.perm_media_outlined),
              label: const Text('Mehrere Bilder auswählen'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(_statusText ?? 'Wird verarbeitet…')),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String text) {
    return Card(
      color: AppTheme.error.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: AppTheme.error))),
          ],
        ),
      ),
    );
  }

  Widget _materialSummaryCard(MaterialSessionState session) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text('${session.materials.length} Datei(en) erkannt',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (session.anyUnreliable) ...[
              const SizedBox(height: 8),
              const Text(
                '⚠️ Ein oder mehrere Bilder waren schlecht lesbar – das Ergebnis kann unvollständig sein.',
                style: TextStyle(color: Colors.orange, fontSize: 13),
              ),
            ],
            if (session.materials.isNotEmpty && session.materials.last.imageDescription != null) ...[
              const SizedBox(height: 8),
              Text(
                'Erkannt: ${session.materials.last.imageDescription}',
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionGrid() {
    final actions = [
      (_Action.zusammenfassen, Icons.summarize_outlined, 'Zusammenfassen'),
      (_Action.mathe, Icons.calculate_outlined, 'Aufgabe lösen'),
      (_Action.erklaeren, Icons.lightbulb_outline, 'Erklären'),
      (_Action.lernzettel, Icons.note_alt_outlined, 'Lernzettel erstellen'),
      (_Action.quiz, Icons.quiz_outlined, 'Quiz erstellen'),
      (_Action.chat, Icons.chat_bubble_outline, 'Mit der KI chatten'),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: actions.map((a) {
        return _ActionTile(
          icon: a.$2,
          label: a.$3,
          onTap: () => _goToAction(a.$1),
        );
      }).toList(),
    );
  }
}

enum _Action { zusammenfassen, mathe, erklaeren, lernzettel, quiz, chat }

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppTheme.primary, size: 30),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
