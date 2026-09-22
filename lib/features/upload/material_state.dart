import 'dart:io';
import 'package:flutter/foundation.dart';

/// Hält den Zustand des aktuell in Bearbeitung befindlichen Materials
/// (ein oder mehrere hochgeladene Bilder/Dateien + erkannter Text).
class UploadedMaterial {
  final File? imageFile;
  final String recognizedText;
  final bool ocrReliable;
  final String? imageDescription;

  UploadedMaterial({
    this.imageFile,
    required this.recognizedText,
    required this.ocrReliable,
    this.imageDescription,
  });
}

class MaterialSessionState extends ChangeNotifier {
  final List<UploadedMaterial> _materials = [];

  List<UploadedMaterial> get materials => List.unmodifiable(_materials);

  bool get hasMaterial => _materials.isNotEmpty;

  /// Kombinierter Text aus allen aktuell hochgeladenen Dateien –
  /// wird als Grundlage für alle KI-Funktionen verwendet.
  String get combinedText =>
      _materials.map((m) => m.recognizedText).where((t) => t.trim().isNotEmpty).join('\n\n---\n\n');

  bool get anyUnreliable => _materials.any((m) => !m.ocrReliable);

  void addMaterial(UploadedMaterial material) {
    _materials.add(material);
    notifyListeners();
  }

  void clear() {
    _materials.clear();
    notifyListeners();
  }

  void removeAt(int index) {
    _materials.removeAt(index);
    notifyListeners();
  }
}
