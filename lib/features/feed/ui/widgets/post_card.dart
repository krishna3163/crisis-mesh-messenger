import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/feed_post.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class PostCard extends StatelessWidget {
  final FeedPost post;
  final VoidCallback onTap;

  const PostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedService = context.read<FeedService>();
    final meshService = context.read<MeshNetworkService>();
    final currentUserId = meshService.deviceId ?? '';
    final isLiked = post.likedBy.contains(currentUserId);

    final formattedTime = DateFormat('MMM dd, HH:mm').format(post.timestamp);
    final commentsCount = feedService.getCommentsForPost(post.id).length;

    // Use nice gradient background for avatar based on author name hash
    final avatarColor = Colors.primaries[post.authorName.hashCode % Colors.primaries.length];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  // Hop badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getHopColor(post.hopCount).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getHopColor(post.hopCount).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.radar_rounded,
                          size: 12,
                          color: _getHopColor(post.hopCount),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.hopCount == 0 ? 'Direct' : '${post.hopCount} Hops',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: _getHopColor(post.hopCount),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Like button
                  InkWell(
                    onTap: () => feedService.toggleLike(post.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            isLiked ? Icons.favorite : Icons.favorite_border,
                            color: isLiked ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${post.likedBy.length}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isLiked ? Colors.red : theme.colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Comment button
                  InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$commentsCount',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Relay info (simple route visualization count)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.share_outlined,
                      color: theme.colorScheme.onSurface.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getHopColor(int hopCount) {
    if (hopCount == 0) return Colors.green;
    if (hopCount < 3) return Colors.blue;
    if (hopCount < 6) return Colors.orange;
    return Colors.red;
  }
}
