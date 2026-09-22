import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'models.dart';

/// Zentrale lokale Datenbank der App. Alle Ergebnisse (Zusammenfassungen,
/// Lernzettel, Quiz, Matheaufgaben) und Chatverläufe werden hier
/// dauerhaft auf dem Gerät gespeichert – auch offline verfügbar.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _init();
    return _db!;
  }

  Future<Database> _init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lernapp.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE history_entries (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            sourceImagePath TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE chat_messages (
            id TEXT PRIMARY KEY,
            chatId TEXT NOT NULL,
            isUser INTEGER NOT NULL,
            text TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_chat_chatId ON chat_messages(chatId)');
      },
    );
  }

  // ---------- Verlauf ----------

  Future<void> insertHistoryEntry(HistoryEntry entry) async {
    final db = await database;
    await db.insert('history_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<HistoryEntry>> getAllHistoryEntries({String? searchQuery}) async {
    final db = await database;
    List<Map<String, Object?>> rows;
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      rows = await db.query(
        'history_entries',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'createdAt DESC',
      );
    } else {
      rows = await db.query('history_entries', orderBy: 'createdAt DESC');
    }
    return rows.map(HistoryEntry.fromMap).toList();
  }

  Future<void> deleteHistoryEntry(String id) async {
    final db = await database;
    await db.delete('history_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateHistoryEntryContent(String id, String newContent) async {
    final db = await database;
    await db.update('history_entries', {'content': newContent},
        where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Chats ----------

  Future<void> insertChatMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('chat_messages', message.toMap());
  }

  Future<List<ChatMessage>> getChatMessages(String chatId) async {
    final db = await database;
    final rows = await db.query('chat_messages',
        where: 'chatId = ?', whereArgs: [chatId], orderBy: 'createdAt ASC');
    return rows.map(ChatMessage.fromMap).toList();
  }

  Future<void> deleteChat(String chatId) async {
    final db = await database;
    await db.delete('chat_messages', where: 'chatId = ?', whereArgs: [chatId]);
  }
}
