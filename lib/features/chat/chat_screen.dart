import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../core/ai/ai_provider.dart';
import '../../core/ai/ai_provider_factory.dart';
import '../../core/ai/prompts.dart';
import '../../core/db/app_database.dart';
import '../../core/db/models.dart';
import '../../core/theme.dart';

class ChatScreen extends StatefulWidget {
  final String material;
  final String? existingChatId;

  const ChatScreen({super.key, required this.material, this.existingChatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final String _chatId;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _chatId = widget.existingChatId ?? const Uuid().v4();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final msgs = await AppDatabase.instance.getChatMessages(_chatId);
    setState(() => _messages = msgs);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      chatId: _chatId,
      isUser: true,
      text: text,
      createdAt: DateTime.now(),
    );
    await AppDatabase.instance.insertChatMessage(userMsg);
    setState(() {
      _messages = [..._messages, userMsg];
      _sending = true;
      _error = null;
    });
    _scrollToBottom();

    try {
      final provider = await AiProviderFactory.current();
      final answer = await provider.generateText(
        Prompts.chatWithMaterial(material: widget.material, frage: text),
      );
      final aiMsg = ChatMessage(
        id: const Uuid().v4(),
        chatId: _chatId,
        isUser: false,
        text: answer,
        createdAt: DateTime.now(),
      );
      await AppDatabase.instance.insertChatMessage(aiMsg);
      setState(() {
        _messages = [..._messages, aiMsg];
        _sending = false;
      });
      _scrollToBottom();
    } on MissingApiKeyException catch (e) {
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } on AiRequestException catch (e) {
      setState(() {
        _sending = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _sending = false;
        _error = 'Unerwarteter Fehler: $e';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KI-Chat zum Material')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _messages.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Stell eine Frage zu deinem hochgeladenen Material.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _bubble(_messages[index]),
                    ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(_error!, style: const TextStyle(color: AppTheme.error, fontSize: 13)),
              ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            _inputBar(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(ChatMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText(
          msg.text,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.4),
        ),
      ),
    );
  }

  Widget _inputBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Frage eingeben…'),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _sending ? null : _send,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
