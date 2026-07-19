import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/message.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import 'package:crisis_mesh/features/messaging/ui/widgets/message_bubble.dart';

/// Chat screen for messaging with a specific peer
class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerName;

  const ChatScreen({
    required this.peerId,
    required this.peerName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _storageService = getIt<MessageStorageService>();
  final _uuid = const Uuid();

  List<Message> _messages = [];
  bool _isPeerTyping = false;
  bool _isTyping = false;
  Timer? _typingDebounceTimer;
  Message? _replyingTo;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupMessageListener();
    _messageController.addListener(_onTextChanged);
  }

  void _loadMessages() {
    final meshService = context.read<MeshNetworkService>();
    final deviceId = meshService.deviceId ?? '';

    setState(() {
      _messages = _storageService.getMessagesForConversation(
        widget.peerId,
        deviceId,
      );
    });

    // Mark conversation as read
    final conversation = _storageService.getConversationByPeer(widget.peerId);
    if (conversation != null) {
      _storageService.markConversationAsRead(conversation.id);
    }
    
    // Trigger read receipts for incoming unread messages
    _markMessagesAsRead();
  }

  void _markMessagesAsRead() {
    final meshService = context.read<MeshNetworkService>();
    bool changed = false;

    for (int i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.senderId == widget.peerId && msg.status != MessageStatus.read) {
        final updated = msg.copyWith(status: MessageStatus.read);
        _storageService.saveMessage(updated);
        meshService.sendReadReceipt(updated.id, widget.peerId);
        _messages[i] = updated;
        changed = true;
      }
    }
    if (changed) {
      setState(() {});
    }
  }

  void _setupMessageListener() {
    final meshService = context.read<MeshNetworkService>();
    
    // Handle incoming messages
    meshService.onMessageReceived = (message) {
      if (message.senderId == widget.peerId) {
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();

        // Mark as read and send read receipt immediately
        meshService.sendReadReceipt(message.id, widget.peerId);
        _updateLocalMessageStatus(message.id, MessageStatus.read);
      }
    };

    // Handle typing status
    meshService.onTypingStatusChanged = (peerId, isTyping) {
      if (peerId == widget.peerId) {
        setState(() {
          _isPeerTyping = isTyping;
        });
      }
    };

    // Handle message status updates
    meshService.onMessageStatusChanged = (msgId, peerId, status) {
      if (peerId == widget.peerId) {
        final index = _messages.indexWhere((m) => m.id == msgId);
        if (index != -1) {
          setState(() {
            _messages[index] = _messages[index].copyWith(status: status);
          });
        }
      }
    };

    // Handle remote deletions
    meshService.onMessageDeleted = (msgId) {
      setState(() {
        _messages.removeWhere((m) => m.id == msgId);
      });
    };
  }

  void _updateLocalMessageStatus(String messageId, MessageStatus status) {
    final index = _messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      final updated = _messages[index].copyWith(status: status);
      _storageService.saveMessage(updated);
      setState(() {
        _messages[index] = updated;
      });
    }
  }

  void _onTextChanged() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<MeshNetworkService>().sendTypingStatus(widget.peerId, true);
    }

    _typingDebounceTimer?.cancel();
    _typingDebounceTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        if (mounted) {
          context.read<MeshNetworkService>().sendTypingStatus(widget.peerId, false);
        }
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final meshService = context.read<MeshNetworkService>();
    final deviceId = meshService.deviceId ?? '';

    final message = Message(
      id: _uuid.v4(),
      senderId: deviceId,
      recipientId: widget.peerId,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToId: _replyingTo?.id,
      replyToContent: _replyingTo?.content,
      replyToSenderName: _replyingTo != null
          ? (_replyingTo!.senderId == deviceId ? 'You' : widget.peerName)
          : null,
    );

    setState(() {
      _messages.add(message);
      _replyingTo = null; // Clear reply state
    });

    _messageController.clear();
    _scrollToBottom();

    // Reset typing state
    if (_isTyping) {
      _isTyping = false;
      meshService.sendTypingStatus(widget.peerId, false);
    }

    // Send through mesh network
    meshService.sendMessage(message).then((success) {
      if (success) {
        final updatedMessage = message.copyWith(status: MessageStatus.sent);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
        _storageService.saveMessage(updatedMessage);
      } else {
        final updatedMessage = message.copyWith(status: MessageStatus.failed);
        setState(() {
          final index = _messages.indexWhere((m) => m.id == message.id);
          if (index != -1) {
            _messages[index] = updatedMessage;
          }
        });
        _storageService.saveMessage(updatedMessage);
      }
    });

    // Update conversation
    _storageService.updateConversationWithMessage(
      message,
      deviceId,
      widget.peerName,
    );
  }

  void _showForwardDialog(Message originalMessage) {
    final meshService = context.read<MeshNetworkService>();
    final onlinePeers = meshService.onlinePeers;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forward Message'),
        content: onlinePeers.isEmpty
            ? const Text('No online peers available to forward to.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: onlinePeers.length,
                  itemBuilder: (context, index) {
                    final peer = onlinePeers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(peer.name[0].toUpperCase()),
                      ),
                      title: Text(peer.name),
                      onTap: () {
                        final myDeviceId = meshService.deviceId ?? '';
                        final forwardedMessage = Message(
                          id: _uuid.v4(),
                          senderId: myDeviceId,
                          recipientId: peer.id,
                          content: originalMessage.content,
                          timestamp: DateTime.now(),
                          status: MessageStatus.sending,
                        );

                        meshService.sendMessage(forwardedMessage).then((success) {
                          final status = success ? MessageStatus.sent : MessageStatus.failed;
                          _storageService.saveMessage(forwardedMessage.copyWith(status: status));
                        });

                        _storageService.updateConversationWithMessage(
                          forwardedMessage,
                          myDeviceId,
                          peer.name,
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Message forwarded to ${peer.name}')),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final meshService = context.watch<MeshNetworkService>();
    final peer = meshService.peers.where((p) => p.id == widget.peerId).firstOrNull;
    final isOnline = peer?.isAvailable ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.peerName),
            Text(
              _isPeerTyping
                  ? 'typing...'
                  : (isOnline ? 'Online' : 'Offline'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isPeerTyping
                        ? Colors.blueAccent
                        : (isOnline ? Colors.green : Colors.grey),
                    fontWeight: _isPeerTyping ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showPeerInfo(peer);
            },
            tooltip: 'Peer Info',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.withOpacity(0.2),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Peer is offline. Messages will be delivered when they come online.',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      );
    }

    final meshService = context.read<MeshNetworkService>();
    final currentUserId = meshService.deviceId ?? '';

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;

        return MessageBubble(
          message: message,
          isMe: isMe,
          onReply: () {
            setState(() {
              _replyingTo = message;
            });
          },
          onForward: () {
            _showForwardDialog(message);
          },
          onDeleteLocal: () {
            _storageService.deleteMessage(message.id);
            setState(() {
              _messages.removeAt(index);
            });
          },
          onDeleteRemote: () {
            _storageService.deleteMessage(message.id);
            setState(() {
              _messages.removeAt(index);
            });
            context.read<MeshNetworkService>().sendRemoteDelete(message.id, widget.peerId);
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyingTo != null) _buildReplyPreview(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  tooltip: 'Send',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Row(
        children: [
          const Icon(Icons.reply, size: 20, color: Colors.blueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyingTo!.senderId == context.read<MeshNetworkService>().deviceId
                      ? 'You'
                      : widget.peerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.blueAccent,
                  ),
                ),
                Text(
                  _replyingTo!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              setState(() {
                _replyingTo = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _showPeerInfo(dynamic peer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.peerName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('ID', widget.peerId),
            _infoRow('Status', peer?.status.name ?? 'Unknown'),
            _infoRow('Device', peer?.deviceType ?? 'Unknown'),
            if (peer != null) ...[
              _infoRow('Signal', '${peer.connectionQuality}%'),
              _infoRow('Messages', '${_messages.length}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final meshService = context.read<MeshNetworkService>();
    meshService.onMessageReceived = null;
    meshService.onMessageStatusChanged = null;
    meshService.onMessageDeleted = null;
    meshService.onTypingStatusChanged = null;
    _typingDebounceTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
