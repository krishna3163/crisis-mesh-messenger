import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'channel_message.g.dart';

@HiveType(typeId: 7)
class ChannelMessage extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String channelId;

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String senderName;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final int hopCount;

  @HiveField(7)
  final List<String> routePath;

  const ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.timestamp,
    this.hopCount = 0,
    this.routePath = const [],
  });

  ChannelMessage incrementHop(String nodeId) {
    return ChannelMessage(
      id: id,
      channelId: channelId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      timestamp: timestamp,
      hopCount: hopCount + 1,
      routePath: [...routePath, nodeId],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'channelId': channelId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'hopCount': hopCount,
        'routePath': routePath,
      };

  factory ChannelMessage.fromJson(Map<String, dynamic> json) {
    return ChannelMessage(
      id: json['id'] as String,
      channelId: json['channelId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      hopCount: json['hopCount'] as int? ?? 0,
      routePath: (json['routePath'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  List<Object?> get props => [id, channelId, senderId, senderName, content, timestamp, hopCount, routePath];
}
