import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'feed_comment.g.dart';

@HiveType(typeId: 8)
class FeedComment extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String postId;

  @HiveField(2)
  final String authorId;

  @HiveField(3)
  final String authorName;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final DateTime timestamp;

  const FeedComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'postId': postId,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
      };

  factory FeedComment.fromJson(Map<String, dynamic> json) {
    return FeedComment(
      id: json['id'] as String,
      postId: json['postId'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [id, postId, authorId, authorName, content, timestamp];
}
