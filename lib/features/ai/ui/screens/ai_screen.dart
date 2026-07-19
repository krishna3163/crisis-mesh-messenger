import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/ai/ai_service.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  void _askAI() async {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': query});
      _isLoading = true;
      _queryController.clear();
    });

    final aiService = context.read<AIService>();
    final result = await aiService.getEmergencyGuidance(query);

    setState(() {
      _messages.add({'role': 'ai', 'content': result});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Emergency Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => setState(() => _messages.clear()),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInfoBanner(),
          Expanded(child: _buildChatList()),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      color: Colors.blue.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.offline_bolt, color: Colors.blue, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Offline-first inference. No internet required.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('How can I help you today?', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Ask about "CPR" or "burn treatment"', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageBubble(msg['content']!, isUser);
      },
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    // Check if content has newlines (structured steps)
    final lines = content.split('\n');
    final isStructured = !isUser && lines.length > 1;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue.shade600 : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: Radius.circular(isUser ? 12 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.smart_toy, size: 12, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('AI Assistant', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            if (isStructured)
               ...lines.map((line) => Padding(
                 padding: const EdgeInsets.symmetric(vertical: 2),
                 child: Text(line, style: const TextStyle(color: Colors.black87)),
               ))
            else
              Text(
                content,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _queryController,
                decoration: const InputDecoration(
                  hintText: 'Type your emergency question...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _askAI(),
              ),
            ),
            IconButton(
              onPressed: _askAI,
              icon: const Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
