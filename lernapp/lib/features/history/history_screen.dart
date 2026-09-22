import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/db/app_database.dart';
import '../../core/db/models.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry> _entries = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await AppDatabase.instance.getAllHistoryEntries(searchQuery: _query);
    setState(() {
      _entries = entries;
      _loading = false;
    });
  }

  IconData _iconFor(EntryType type) {
    switch (type) {
      case EntryType.zusammenfassung:
        return Icons.summarize_outlined;
      case EntryType.mathe:
        return Icons.calculate_outlined;
      case EntryType.erklaerung:
        return Icons.lightbulb_outline;
      case EntryType.lernzettel:
        return Icons.note_alt_outlined;
      case EntryType.quiz:
        return Icons.quiz_outlined;
      case EntryType.chat:
        return Icons.chat_bubble_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verlauf')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Verlauf durchsuchen…',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) {
                  _query = v;
                  _load();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _entries.isEmpty
                      ? const Center(
                          child: Text('Noch keine gespeicherten Ergebnisse.',
                              style: TextStyle(color: Colors.black54)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final e = _entries[index];
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: AppTheme.primary.withOpacity(0.1),
                                  child: Icon(_iconFor(e.type), color: AppTheme.primary, size: 20),
                                ),
                                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${e.type.label} · ${DateFormat('dd.MM.yyyy HH:mm').format(e.createdAt)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                  onPressed: () async {
                                    await AppDatabase.instance.deleteHistoryEntry(e.id);
                                    _load();
                                  },
                                ),
                                onTap: () => _openEntry(e),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  void _openEntry(HistoryEntry e) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(e.content, style: const TextStyle(height: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
