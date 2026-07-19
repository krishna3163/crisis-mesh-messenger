import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/channel.dart';
import 'package:crisis_mesh/core/models/channel_message.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class ChannelChatScreen extends StatefulWidget {
  final String channelId;

  const ChannelChatScreen({
    super.key,
    required this.channelId,
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  final TextEditingController _msgController = TextEditingController();

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    final channelService = context.read<ChannelService>();
    await channelService.sendChannelMessage(widget.channelId, text);
    _msgController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelService = context.watch<ChannelService>();
    final meshService = context.read<MeshNetworkService>();

    final myDeviceId = meshService.deviceId ?? 'unknown';

    // Get channel
    final joinedChannels = channelService.getJoinedChannels();
    final discChannels = channelService.getDiscoverableChannels();
    final allChannels = [...joinedChannels, ...discChannels];
    final channelIndex = allChannels.indexWhere((c) => c.id == widget.channelId);

    if (channelIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Channel Chat')),
        body: const Center(child: Text('Channel not found')),
      );
    }

    final channel = allChannels[channelIndex];
    final isCreator = channel.creatorId == myDeviceId;
    final isSubscribed = channelService.isJoined(channel.id);
    final messages = channelService.getChannelMessages(channel.id);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(channel.name),
            Text(
              channel.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          if (isSubscribed)
            TextButton(
              onPressed: () {
                channelService.leaveChannel(channel.id);
                Navigator.pop(context);
              },
              child: const Text('Unsubscribe', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages thread
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.speaker_notes,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No broadcasts in this channel yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        if (isCreator)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text('Type below to broadcast your first message.'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == myDeviceId;
                      final formattedTime = DateFormat('HH:mm').format(message.timestamp);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe
                              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
                              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isMe
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.outline.withOpacity(0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  message.senderName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isMe ? theme.colorScheme.primary : null,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  formattedTime,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              message.content,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 4),
                            // Hops information
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  size: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  message.hopCount == 0 ? 'Direct' : '${message.hopCount} Hops',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Message input or Subscribe button
          if (!isSubscribed)
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
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
                child: ElevatedButton.icon(
                  onPressed: () => channelService.joinChannel(channel.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Subscribe to Channel', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            )
          else if (isCreator)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        controller: _msgController,
                        decoration: const InputDecoration(
                          hintText: 'Broadcast a message to this channel...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
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
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              child: SafeArea(
                child: Center(
                  child: Text(
                    'Only administrators can send messages in this channel.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
