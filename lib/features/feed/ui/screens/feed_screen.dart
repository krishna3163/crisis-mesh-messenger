import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/feed_post.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import '../widgets/post_card.dart';
import 'post_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _postController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showCreatePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue),
            SizedBox(width: 8),
            Text('Create Update'),
          ],
        ),
        content: TextField(
          controller: _postController,
          decoration: const InputDecoration(
            hintText: "What's happening in your area?",
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
          maxLength: 280,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = _postController.text.trim();
              if (text.isNotEmpty) {
                final feedService = context.read<FeedService>();
                final meshService = context.read<MeshNetworkService>();
                final userName = meshService.deviceName ?? 'User';

                feedService.createPost(userName, text);
                _postController.clear();
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Update posted and broadcasting to mesh!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final feedService = context.watch<FeedService>();
    final posts = feedService.getAllPosts();

    // Filter posts by search query
    final filteredPosts = posts.where((post) {
      final query = _searchQuery.toLowerCase();
      return post.content.toLowerCase().contains(query) ||
          post.authorName.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search community updates...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: theme.colorScheme.outline.withOpacity(0.3)),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
            ),
          ),

          // Posts List
          Expanded(
            child: filteredPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rss_feed,
                          size: 64,
                          color: theme.colorScheme.primary.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No updates match your search'
                              : 'No community updates yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Try searching for different keywords'
                              : 'Tap the button below to share an offline update',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      final post = filteredPosts[index];
                      return PostCard(
                        post: post,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailScreen(postId: post.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        icon: const Icon(Icons.edit),
        label: const Text('New Post'),
      ),
    );
  }
}
