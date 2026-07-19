import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'feed_post.g.dart';

/// A social feed post shared over the mesh network
@HiveType(typeId: 5)
class FeedPost extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String authorId;

  @HiveField(2)
  final String authorName;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime timestamp;

  @HiveField(5)
  final List<String> routePath;

  @HiveField(6)
  final int hopCount;

  @HiveField(7)
  final List<String> likedBy;

  const FeedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.routePath = const [],
    this.hopCount = 0,
    this.likedBy = const [],
  });

  FeedPost incrementHop(String nodeId) {
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      content: content,
      timestamp: timestamp,
      routePath: [...routePath, nodeId],
      hopCount: hopCount + 1,
      likedBy: likedBy,
    );
  }

  FeedPost toggleLike(String userId) {
    final updatedLikes = List<String>.from(likedBy);
    if (updatedLikes.contains(userId)) {
      updatedLikes.remove(userId);
    } else {
      updatedLikes.add(userId);
    }
    return FeedPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      content: content,
      timestamp: timestamp,
      routePath: routePath,
      hopCount: hopCount,
      likedBy: updatedLikes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorId': authorId,
        'authorName': authorName,
        'content': content,
        'timestamp': timestamp.toIso8601String(),
        'routePath': routePath,
        'hopCount': hopCount,
        'likedBy': likedBy,
      };

  factory FeedPost.fromJson(Map<String, dynamic> json) {
    return FeedPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      routePath: (json['routePath'] as List?)?.cast<String>() ?? [],
      hopCount: json['hopCount'] as int? ?? 0,
      likedBy: (json['likedBy'] as List?)?.cast<String>() ?? [],
    );
  }

  @override
  List<Object?> get props => [id, authorId, authorName, content, timestamp, routePath, hopCount, likedBy];
}
