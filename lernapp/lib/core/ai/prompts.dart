/// Zentrale Prompt-Vorlagen. Hier an einer Stelle gesammelt, damit sie
/// leicht angepasst werden können, ohne die UI-Screens zu verändern.
class Prompts {
  static String summarize(String text, {required String art}) => '''
Du bist eine Lernhilfe für Schüler. Fasse den folgenden Text als "$art" zusammen.
Arbeite die wichtigsten Informationen klar heraus und stelle sie übersichtlich dar
(z. B. mit Überschriften und Stichpunkten, wo es sinnvoll ist).
Verwende einfache, verständliche Sprache. Erfinde keine Informationen, die nicht im Text stehen.

Text:
"""
$text
"""
''';

  static String solveMath(String text) => '''
Du bist eine Mathe-Lernhilfe für Schüler. Löse die folgende(n) Aufgabe(n) Schritt für Schritt.
Wenn mehrere Aufgaben im Text enthalten sind, löse jede einzeln und nummeriere sie getrennt.

Für jede Aufgabe:
1. Erkenne, was gesucht ist.
2. Zeige den vollständigen Rechenweg, Schritt für Schritt, mit kurzer Begründung je Schritt.
3. Überprüfe dein Ergebnis anschließend selbst (z. B. durch Gegenrechnen oder Einsetzen),
   bevor du das Endergebnis nennst.
4. Nenne am Ende klar das Endergebnis, gekennzeichnet mit "Ergebnis:".

Wenn die Aufgabe nicht eindeutig lesbar oder unvollständig ist, sage das ehrlich,
anstatt eine Aufgabe zu erfinden.

Aufgabe(n):
"""
$text
"""
''';

  static String explain(String text) => '''
Du bist eine Lernhilfe für Schüler. Erkläre den folgenden Inhalt verständlich,
so als würdest du es einem Schüler erklären, der das Thema noch nicht kennt.
Nutze einfache Sprache, kleine Beispiele wo hilfreich, und baue die Erklärung
logisch aufeinander auf.

Inhalt:
"""
$text
"""
''';

  static String lernzettel(String text) => '''
Erstelle aus dem folgenden Inhalt einen übersichtlichen Lernzettel für Schüler.
Struktur:
- Wichtigste Begriffe mit kurzer Erklärung
- Wichtigste Fakten/Formeln als Stichpunkte
- Kurze Zusammenfassung am Ende (3-5 Sätze)

Inhalt:
"""
$text
"""
''';

  static String quiz(String text, {int anzahl = 5}) => '''
Erstelle aus dem folgenden Inhalt ein Quiz mit $anzahl Multiple-Choice-Fragen für Schüler.
Format für jede Frage GENAU so:

Frage X: <Fragetext>
A) <Antwort>
B) <Antwort>
C) <Antwort>
D) <Antwort>
Richtig: <Buchstabe>
Erklärung: <kurze Erklärung, warum diese Antwort richtig ist>

Inhalt:
"""
$text
"""
''';

  static String imageAnalysis() => '''
Schau dir das Bild genau an und beschreibe in 1-2 kurzen Sätzen, was auf dem Bild
zu sehen ist (z. B. "Matheaufgabe zu quadratischen Gleichungen", "Textseite aus einem
Geschichtsbuch über den Zweiten Weltkrieg", "Diagramm zum Wasserkreislauf").
Wenn das Bild zu unscharf oder unklar ist, um es sicher einzuordnen, sage das ehrlich,
anstatt zu raten.
''';

  static String chatWithMaterial({
    required String material,
    required String frage,
  }) => '''
Du bist eine Lernhilfe für Schüler und hilfst bei Fragen zu folgendem Material.
Antworte ausschließlich auf Basis des Materials, wenn die Frage sich darauf bezieht.
Wenn die Information nicht im Material enthalten ist, sage das ehrlich.

Material:
"""
$material
"""

Frage des Schülers: $frage
''';
}
