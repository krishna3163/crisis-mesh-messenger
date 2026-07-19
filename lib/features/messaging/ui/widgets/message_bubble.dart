import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:crisis_mesh/core/models/message.dart';

/// A chat message bubble
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onReply;
  final VoidCallback? onForward;
  final VoidCallback? onDeleteLocal;
  final VoidCallback? onDeleteRemote;
  final String? senderName;

  const MessageBubble({
    required this.message,
    required this.isMe,
    this.onReply,
    this.onForward,
    this.onDeleteLocal,
    this.onDeleteRemote,
    this.senderName,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: () {
          final RenderBox button = context.findRenderObject() as RenderBox;
          final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
          final RelativeRect position = RelativeRect.fromRect(
            Rect.fromPoints(
              button.localToGlobal(Offset.zero, ancestor: overlay),
              button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
            ),
            Offset.zero & overlay.size,
          );
          
          showMenu(
            context: context,
            position: position,
            items: [
              const PopupMenuItem(
                value: 'reply',
                child: Row(
                  children: [
                    Icon(Icons.reply, size: 20),
                    SizedBox(width: 8),
                    Text('Reply'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'forward',
                child: Row(
                  children: [
                    Icon(Icons.forward, size: 20),
                    SizedBox(width: 8),
                    Text('Forward'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete_local',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Delete for Me', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
              if (isMe)
                const PopupMenuItem(
                  value: 'delete_remote',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text('Delete for Everyone', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
            ],
          ).then((value) {
            if (value == 'reply') onReply?.call();
            if (value == 'forward') onForward?.call();
            if (value == 'delete_local') onDeleteLocal?.call();
            if (value == 'delete_remote') onDeleteRemote?.call();
          });
        },
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMe ? 16 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (senderName != null && !isMe) ...[
                Text(
                  senderName!,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // Quoted reply rendering
              if (message.replyToId != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withOpacity(0.15)
                        : theme.colorScheme.onSurface.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                      left: BorderSide(
                        color: isMe ? Colors.white : theme.colorScheme.primary,
                        width: 4,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.replyToSenderName ?? 'Unknown',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: isMe ? Colors.white : theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message.replyToContent ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isMe
                              ? colorScheme.onPrimary.withOpacity(0.8)
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Text(
                message.content,
                style: TextStyle(
                  color: isMe ? colorScheme.onPrimary : colorScheme.onSurface,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isMe
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 11,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    _buildStatusIcon(colorScheme),
                  ],
                  if (message.hopCount > 0) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.repeat,
                      size: 12,
                      color: isMe
                          ? colorScheme.onPrimary.withOpacity(0.7)
                          : colorScheme.onSurface.withOpacity(0.6),
                    ),
                    Text(
                      ' ${message.hopCount}',
                      style: TextStyle(
                        color: isMe
                            ? colorScheme.onPrimary.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time,
          size: 12,
          color: colorScheme.onPrimary.withOpacity(0.7),
        );
      case MessageStatus.sent:
        return Icon(
          Icons.check,
          size: 12,
          color: colorScheme.onPrimary.withOpacity(0.7),
        );
      case MessageStatus.delivered:
        return Icon(
          Icons.done_all,
          size: 12,
          color: colorScheme.onPrimary.withOpacity(0.7),
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blueAccent,
        );
      case MessageStatus.failed:
        return Icon(
          Icons.error_outline,
          size: 12,
          color: Colors.red[300],
        );
      case MessageStatus.relayed:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return DateFormat('MMM d, HH:mm').format(timestamp);
    } else {
      return DateFormat('HH:mm').format(timestamp);
    }
  }
}
