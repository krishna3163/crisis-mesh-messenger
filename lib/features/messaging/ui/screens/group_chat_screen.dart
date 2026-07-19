import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/message.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import 'package:crisis_mesh/features/messaging/ui/widgets/message_bubble.dart';
import 'group_details_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    required this.groupId,
    required this.groupName,
    super.key,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _storageService = getIt<MessageStorageService>();

  List<Message> _messages = [];
  String _myDeviceId = '';

  @override
  void initState() {
    super.initState();
    final meshService = context.read<MeshNetworkService>();
    _myDeviceId = meshService.deviceId ?? '';
    _loadMessages();
    _setupMessageListener();
  }

  void _loadMessages() {
    setState(() {
      _messages = _storageService.getMessagesForConversation(
        widget.groupId,
        _myDeviceId,
      );
    });

    // Mark conversation as read
    final conversation = _storageService.getConversationByPeer(widget.groupId);
    if (conversation != null) {
      _storageService.markConversationAsRead(conversation.id);
    }
  }

  void _setupMessageListener() {
    final groupService = context.read<GroupService>();
    groupService.onGroupMessageReceived = (message) {
      if (message.groupId == widget.groupId && message.senderId != _myDeviceId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    };
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final groupService = context.read<GroupService>();

    _messageController.clear();

    try {
      await groupService.sendGroupMessage(widget.groupId, text);
      _loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send group message: $e')),
        );
      }
    }
  }

  String _getSenderName(String senderId) {
    final meshService = context.read<MeshNetworkService>();
    final peer = meshService.peers.firstWhere(
      (p) => p.id == senderId,
      orElse: () => const MeshNetworkService().peers.isEmpty ? null : null, // dummy
    );
    if (peer != null) return peer.name;
    
    // Check if the sender name is embedded in conversation/group members if cached
    final groupService = context.read<GroupService>();
    final group = groupService.getGroup(widget.groupId);
    if (group?.creatorId == senderId) return 'Creator';
    
    return 'Node ${senderId.substring(0, min(5, senderId.length))}';
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.groupName),
            Consumer<GroupService>(
              builder: (context, groupService, child) {
                final group = groupService.getGroup(widget.groupId);
                final memberCount = group?.memberIds.length ?? 0;
                return Text(
                  '$memberCount members',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailsScreen(
                    groupId: widget.groupId,
                  ),
                ),
              );
            },
            tooltip: 'Group Details',
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner indicating Group/Mesh Routing
          Container(
            width: double.infinity,
            color: theme.colorScheme.secondaryContainer.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.hub_outlined, color: theme.colorScheme.secondary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Group messages are relayed over mesh to all members.',
                    style: TextStyle(color: theme.colorScheme.onSecondaryContainer, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Say hello to the group!',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = message.senderId == _myDeviceId;
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        senderName: isMe ? 'You' : _getSenderName(message.senderId),
                        onDeleteLocal: () async {
                          await _storageService.deleteMessage(message.id);
                          _loadMessages();
                        },
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message group...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildGroupDetails(BuildContext context) {
    return Container();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final groupService = context.read<GroupService>();
    groupService.onGroupMessageReceived = null;
    super.dispose();
  }
}
