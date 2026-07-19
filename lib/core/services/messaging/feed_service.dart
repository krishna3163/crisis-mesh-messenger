import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import '../../models/feed_post.dart';
import '../../models/feed_comment.dart';
import '../mesh/mesh_network_service.dart';

/// Service for managing social feed posts (Phase 1 Moonshot)
class FeedService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  static const String _feedBoxName = 'feed_posts';
  static const String _commentsBoxName = 'feed_comments';

  Box<FeedPost>? _feedBox;
  Box<FeedComment>? _commentsBox;

  final MeshNetworkService _meshService;

  FeedService(this._meshService);

  /// Initialize storage and listeners
  Future<void> initialize() async {
    _logger.i('Initializing feed service...');

    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(FeedPostAdapter());
    }
    if (!Hive.isAdapterRegistered(8)) {
      Hive.registerAdapter(FeedCommentAdapter());
    }

    _feedBox = await Hive.openBox<FeedPost>(_feedBoxName);
    _commentsBox = await Hive.openBox<FeedComment>(_commentsBoxName);

    _logger.i('Feed service initialized: ${_feedBox?.length} posts and ${_commentsBox?.length} comments loaded.');
  }

  /// Create and share a new post
  Future<void> createPost(String authorName, String content) async {
    final deviceId = _meshService.deviceId ?? 'unknown';
    final post = FeedPost(
      id: _uuid.v4(),
      authorId: deviceId,
      authorName: authorName,
      content: content,
      timestamp: DateTime.now(),
    );

    await _savePost(post);
    await _broadcastPost(post);
  }

  /// Toggle like status of a post
  Future<void> toggleLike(String postId) async {
    final post = _feedBox?.get(postId);
    if (post == null) return;

    final deviceId = _meshService.deviceId ?? 'unknown';
    final updatedPost = post.toggleLike(deviceId);
    await _savePost(updatedPost);

    // Broadcast the like event
    await _broadcastLike(postId, deviceId);
  }

  /// Add comment to a post
  Future<void> addComment(String postId, String authorName, String content) async {
    final deviceId = _meshService.deviceId ?? 'unknown';
    final comment = FeedComment(
      id: _uuid.v4(),
      postId: postId,
      authorId: deviceId,
      authorName: authorName,
      content: content,
      timestamp: DateTime.now(),
    );

    await _saveComment(comment);
    await _broadcastComment(comment);
  }

  /// Get all posts sorted by timestamp
  List<FeedPost> getAllPosts() {
    if (_feedBox == null) return [];
    return _feedBox!.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get comments for a post sorted by timestamp (oldest first)
  List<FeedComment> getCommentsForPost(String postId) {
    if (_commentsBox == null) return [];
    return _commentsBox!.values
        .where((comment) => comment.postId == postId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Handle a post received from the mesh
  Future<void> handleReceivedPost(FeedPost post) async {
    if (_feedBox?.containsKey(post.id) ?? true) return;

    _logger.i('Received new feed post from ${post.authorName}');
    await _savePost(post);

    // Relay the post if it hasn't exceeded hop limit
    if (post.hopCount < 20) { 
      await _broadcastPost(post);
    }
  }

  /// Handle a like event received from the mesh
  Future<void> handleReceivedLike(String postId, String userId) async {
    final post = _feedBox?.get(postId);
    if (post == null) return;

    if (post.likedBy.contains(userId)) return; // Already liked

    _logger.i('Received like from $userId for post $postId');
    final updatedPost = post.toggleLike(userId);
    await _savePost(updatedPost);

    // Relay the like event
    await _broadcastLike(postId, userId);
  }

  /// Handle a comment received from the mesh
  Future<void> handleReceivedComment(FeedComment comment) async {
    if (_commentsBox?.containsKey(comment.id) ?? true) return;

    _logger.i('Received comment from ${comment.authorName} on post ${comment.postId}');
    await _saveComment(comment);

    // Relay the comment
    await _broadcastComment(comment);
  }

  Future<void> _savePost(FeedPost post) async {
    await _feedBox?.put(post.id, post);
    notifyListeners();
  }

  Future<void> _saveComment(FeedComment comment) async {
    await _commentsBox?.put(comment.id, comment);
    notifyListeners();
  }

  Future<void> _broadcastPost(FeedPost post) async {
    _logger.d('Broadcasting feed post ${post.id}');
    final deviceId = _meshService.deviceId ?? 'unknown';
    final forwarded = post.incrementHop(deviceId);
    await _meshService.broadcastPayload('feed_post', forwarded.toJson());
  }

  Future<void> _broadcastLike(String postId, String userId) async {
    _logger.d('Broadcasting like for post $postId');
    await _meshService.broadcastPayload('feed_like', {
      'postId': postId,
      'userId': userId,
    });
  }

  Future<void> _broadcastComment(FeedComment comment) async {
    _logger.d('Broadcasting comment ${comment.id}');
    await _meshService.broadcastPayload('feed_comment', comment.toJson());
  }
}
