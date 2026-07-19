import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/channel.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'channel_chat_screen.dart';
import 'create_channel_screen.dart';

class ChannelsListScreen extends StatefulWidget {
  const ChannelsListScreen({super.key});

  @override
  State<ChannelsListScreen> createState() => _ChannelsListScreenState();
}

class _ChannelsListScreenState extends State<ChannelsListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final channelService = context.watch<ChannelService>();

    final joinedChannels = channelService.getJoinedChannels();
    final discoverableChannels = channelService.getDiscoverableChannels();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Subscribed'),
              Tab(text: 'Discover Nearby'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChannelList(joinedChannels, true, theme),
          _buildChannelList(discoverableChannels, false, theme),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateChannelScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Channel'),
      ),
    );
  }

  Widget _buildChannelList(List<Channel> channels, bool isSubscribedList, ThemeData theme) {
    if (channels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSubscribedList ? Icons.hub_outlined : Icons.radar_rounded,
              size: 64,
              color: theme.colorScheme.primary.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              isSubscribedList ? 'No subscribed channels yet' : 'No public channels found nearby',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                isSubscribedList
                    ? 'Subscribe to channels nearby or create your own to broadcast updates.'
                    : 'Wait for other devices to broadcast their public channels or create a new one.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final channel = channels[index];
        final channelColor = Colors.primaries[channel.name.hashCode % Colors.primaries.length];

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: channelColor.withOpacity(0.2),
              child: Icon(
                Icons.hub,
                color: channelColor,
              ),
            ),
            title: Text(
              channel.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              channel.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: isSubscribedList
                ? const Icon(Icons.arrow_forward_ios, size: 16)
                : ElevatedButton(
                    onPressed: () {
                      context.read<ChannelService>().joinChannel(channel.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Subscribed to ${channel.name}!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Join'),
                  ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChannelChatScreen(channelId: channel.id),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
