# Lernhilfe – KI-Lern-App für Schüler

Eine vollständige Flutter-App (keine Webseite!) für Android, die Fotos von
Aufgaben/Texten analysiert und per KI zusammenfasst, Matheaufgaben mit
Rechenweg löst, Lernzettel und Quiz erstellt und einen KI-Chat zum
hochgeladenen Material anbietet.

## Was ist enthalten

- **OCR direkt auf dem Gerät** (Google ML Kit) – offline, kostenlos, schnell
- **Austauschbare KI-Anbindung** (`lib/core/ai/ai_provider.dart`) – aktuell
  Google Gemini vorkonfiguriert, OpenAI als zweites Beispiel bereits dabei
- **Lokale Datenbank** (SQLite) für Verlauf, Lernzettel, Quiz und Chats
- **Sauber getrennte Architektur**: `core/` (Datenbank, OCR, KI-Anbindung),
  `features/` (Bildschirme je Funktion)
- Fertiger **GitHub-Actions-Workflow**, der die APK automatisch in der
  Cloud baut – du brauchst dafür **kein Android Studio auf deinem PC**

## Schritt 1: Kostenlosen Gemini-API-Schlüssel holen

1. Gehe zu **aistudio.google.com/apikey**
2. Mit Google-Konto anmelden, auf "Create API key" klicken
3. Schlüssel kopieren – den trägst du später in der App unter
   **Einstellungen** ein (nicht im Code, nicht auf GitHub!)

## Schritt 2: Projekt auf GitHub hochladen

1. Gehe zu **github.com**, erstelle (falls noch nicht vorhanden) ein
   kostenloses Konto
2. Klicke auf **"New repository"**, gib z. B. `lernapp` als Namen ein,
   stelle es auf **Private** (empfohlen) und erstelle es
3. Lade auf der Repository-Seite über **"uploading an existing file"**
   den kompletten Inhalt dieses Projektordners hoch (am einfachsten:
   den heruntergeladenen Ordner als ZIP entpacken und alle Dateien/Ordner
   per Drag & Drop hochladen)
4. Commit bestätigen

## Schritt 3: APK automatisch bauen lassen

1. Öffne in deinem Repository den Tab **"Actions"**
2. Der Workflow **"APK bauen"** startet automatisch nach dem Hochladen.
   Falls nicht: links auf "APK bauen" klicken, dann **"Run workflow"**
3. Warte ca. 5–10 Minuten, bis der Lauf ein grünes Häkchen zeigt
4. Klicke den fertigen Lauf an, scrolle zu **"Artifacts"** und lade
   **`lernapp-release-apk`** herunter – das ist eine ZIP-Datei mit der
   fertigen `app-release.apk` darin

## Schritt 4: APK auf dem Samsung-Handy installieren

1. Entpacke die heruntergeladene ZIP-Datei und übertrage die
   `app-release.apk` auf dein Handy (z. B. per USB-Kabel, Google Drive,
   oder E-Mail an dich selbst)
2. Tippe auf dem Handy auf die APK-Datei
3. Falls Android warnt "Installation aus unbekannten Quellen blockiert":
   Einstellungen öffnen → dieser App (z. B. "Dateien" oder "Chrome")
   erlauben, Apps zu installieren → zurück zur APK, erneut antippen
4. **"Installieren"** antippen – fertig, die App heißt **"Lernhilfe"**

## Schritt 5: In der App den API-Schlüssel eintragen

Beim ersten Start: unten auf **"Einstellungen"** → Gemini ist bereits
ausgewählt → API-Schlüssel aus Schritt 1 einfügen → **"Speichern"**.
Danach funktionieren alle KI-Funktionen.

## Später: KI-Modell wechseln

In `lib/core/ai/` liegt für jeden Anbieter eine eigene Datei
(`gemini_provider.dart`, `openai_provider.dart`). Ein neuer Anbieter
braucht nur eine neue Klasse, die `AiProvider` implementiert – der Rest
der App muss nicht angefasst werden. Die Auswahl selbst treffen Nutzer
in den **Einstellungen** der App.

## Projektstruktur

```
lib/
  core/
    ai/            → austauschbare KI-Anbindung + Prompt-Vorlagen
    db/             → SQLite-Datenbank (Verlauf, Chats)
    ocr/            → Texterkennung mit Qualitätsprüfung
    theme.dart
  features/
    upload/         → Startbildschirm: Foto hochladen, Aktion wählen
    summary/         → Zusammenfassung + generischer Ergebnis-Screen
    math/            → Matheaufgaben mit Rechenweg
    learn/           → Lernzettel & interaktives Quiz
    chat/            → KI-Chat zum hochgeladenen Material
    history/         → Verlauf mit Suche
    settings/        → KI-Anbieter & API-Schlüssel
```

## Lokal bauen (optional, falls du doch Android Studio nutzen willst)

```bash
flutter pub get
flutter build apk --release
```
Die fertige Datei liegt danach unter
`build/app/outputs/flutter-apk/app-release.apk`.
