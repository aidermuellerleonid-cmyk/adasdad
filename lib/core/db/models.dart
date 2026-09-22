/// Typ eines gespeicherten Eintrags im Verlauf.
enum EntryType { zusammenfassung, mathe, erklaerung, lernzettel, quiz, chat }

extension EntryTypeLabel on EntryType {
  String get label {
    switch (this) {
      case EntryType.zusammenfassung:
        return 'Zusammenfassung';
      case EntryType.mathe:
        return 'Matheaufgabe';
      case EntryType.erklaerung:
        return 'Erklärung';
      case EntryType.lernzettel:
        return 'Lernzettel';
      case EntryType.quiz:
        return 'Quiz';
      case EntryType.chat:
        return 'KI-Chat';
    }
  }
}

/// Ein gespeichertes Arbeitsergebnis (Zusammenfassung, Lernzettel, etc.).
class HistoryEntry {
  final String id;
  final EntryType type;
  final String title;
  final String content;
  final String? sourceImagePath;
  final DateTime createdAt;

  HistoryEntry({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    this.sourceImagePath,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'type': type.name,
        'title': title,
        'content': content,
        'sourceImagePath': sourceImagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory HistoryEntry.fromMap(Map<String, Object?> map) => HistoryEntry(
        id: map['id'] as String,
        type: EntryType.values.firstWhere((e) => e.name == map['type']),
        title: map['title'] as String,
        content: map['content'] as String,
        sourceImagePath: map['sourceImagePath'] as String?,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}

/// Eine einzelne Nachricht innerhalb eines KI-Chats zu einem Material.
class ChatMessage {
  final String id;
  final String chatId;
  final bool isUser;
  final String text;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.isUser,
    required this.text,
    required this.createdAt,
  });

  Map<String, Object?> toMap() => {
        'id': id,
        'chatId': chatId,
        'isUser': isUser ? 1 : 0,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ChatMessage.fromMap(Map<String, Object?> map) => ChatMessage(
        id: map['id'] as String,
        chatId: map['chatId'] as String,
        isUser: (map['isUser'] as int) == 1,
        text: map['text'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
}
