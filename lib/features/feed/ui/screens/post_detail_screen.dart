import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/feed_post.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _sendComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    final feedService = context.read<FeedService>();
    final meshService = context.read<MeshNetworkService>();
    final userName = meshService.deviceName ?? 'User';

    feedService.addComment(widget.postId, userName, text);
    _commentController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedService = context.watch<FeedService>();
    final posts = feedService.getAllPosts();

    // Look up current state of the post
    final postIndex = posts.indexWhere((p) => p.id == widget.postId);
    if (postIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Details')),
        body: const Center(child: Text('Post not found')),
      );
    }
    final post = posts[postIndex];
    final comments = feedService.getCommentsForPost(post.id);

    final meshService = context.read<MeshNetworkService>();
    final currentUserId = meshService.deviceId ?? '';
    final isLiked = post.likedBy.contains(currentUserId);
    final formattedTime = DateFormat('MMM dd, HH:mm').format(post.timestamp);

    final avatarColor = Colors.primaries[post.authorName.hashCode % Colors.primaries.length];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Main post details
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: avatarColor.withOpacity(0.2),
                      child: Text(
                        post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : '?',
                        style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.authorName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formattedTime,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  post.content,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 18,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : null,
                      ),
                      onPressed: () => feedService.toggleLike(post.id),
                    ),
                    Text('${post.likedBy.length} Likes'),
                    const SizedBox(width: 24),
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 20,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text('${comments.length} Comments'),
                  ],
                ),
                const Divider(height: 24),
                // Comments list
                Text(
                  'Comments',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No comments yet. Share your thoughts!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  )
                else
                  ...comments.map((comment) {
                    final cAvatarColor = Colors.primaries[comment.authorName.hashCode % Colors.primaries.length];
                    final cTime = DateFormat('HH:mm').format(comment.timestamp);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: cAvatarColor.withOpacity(0.2),
                                child: Text(
                                  comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                                  style: TextStyle(color: cAvatarColor, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                comment.authorName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                cTime,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.only(left: 36),
                            child: Text(
                              comment.content,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
          // Comment input
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
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: InputBorder.none,
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: theme.colorScheme.primary),
                    onPressed: _sendComment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
