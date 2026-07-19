import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/services/rescue/emergency_service.dart';
import 'package:crisis_mesh/features/ai/ui/screens/ai_screen.dart';
import 'package:crisis_mesh/features/maps/ui/screens/map_screen.dart';
import 'package:crisis_mesh/features/feed/ui/screens/feed_screen.dart';
import 'package:crisis_mesh/features/channels/ui/screens/channels_list_screen.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import 'package:crisis_mesh/features/rescue/ui/screens/sos_screen.dart';
import 'package:crisis_mesh/features/rescue/ui/screens/emergency_alerts_screen.dart';
import 'package:crisis_mesh/features/network/ui/screens/network_status_screen.dart';
import 'package:crisis_mesh/features/messaging/ui/widgets/conversation_list_item.dart';
import 'package:crisis_mesh/features/network/ui/widgets/network_status_banner.dart';
import 'chat_screen.dart';
import 'create_group_screen.dart';
import 'group_chat_screen.dart';
import 'package:crisis_mesh/features/network/ui/screens/offline_email_screen.dart';
import 'package:crisis_mesh/features/network/ui/screens/hardware_dashboard_screen.dart';
import 'package:crisis_mesh/features/community/ui/screens/community_hub_screen.dart';

/// Main screen showing conversation list
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = getIt<MessageStorageService>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMeshNetwork();
  }

  Future<void> _initializeMeshNetwork() async {
    final meshService = context.read<MeshNetworkService>();

    // Initialize with device info
    // TODO: Get real device ID and name
    final deviceId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    const deviceName = 'My Device'; // TODO: Let user set this

    await meshService.initialize(deviceId, deviceName);

    // Start scanning and advertising
    await meshService.startScanning();
    await meshService.startAdvertising();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          IconButton(
            icon: const Icon(Icons.email_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OfflineEmailScreen(),
                ),
              );
            },
            tooltip: 'Offline Mail Client',
          ),
          // Emergency alerts button with badge
          Consumer<EmergencyService>(
            builder: (context, emergencyService, child) {
              final criticalCount = emergencyService.criticalSignalsCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.warning_amber_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmergencyAlertsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Emergency Alerts',
                  ),
                  if (criticalCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$criticalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NetworkStatusScreen(),
                ),
              );
            },
            tooltip: 'Network Status',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HardwareDashboardScreen(),
                ),
              );
            },
            tooltip: 'Settings & Sensors',
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hub_outlined),
            activeIcon: Icon(Icons.hub),
            label: 'Channels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy_outlined),
            activeIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rss_feed),
            activeIcon: Icon(Icons.rss_feed_rounded),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups),
            label: 'Community',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showNewConversationDialog,
              icon: const Icon(Icons.message),
              label: const Text('New Message'),
            )
          : null,
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0: return 'Crisis Mesh';
      case 1: return 'Channels';
      case 2: return 'AI Assistant';
      case 3: return 'Live Map';
      case 4: return 'Social Feed';
      case 5: return 'Community Hub';
      default: return 'Crisis Mesh';
    }
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return Column(
          children: [
            const NetworkStatusBanner(),
            // SOS Quick Access Banner
            _buildSOSBanner(),
            Expanded(
              child: _buildConversationList(),
            ),
          ],
        );
      case 1:
        return const ChannelsListScreen();
      case 2:
        return const AIScreen();
      case 3:
        return const MapScreen();
      case 4:
        return const FeedScreen();
      case 5:
        return const CommunityHubScreen();
      default:
        return const Center(child: Text('Unknown Page'));
    }
  }

  Widget _buildPlaceholder(String text, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          ),
          const SizedBox(height: 24),
          Text(
            text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'This module is part of the Phase 1 & 2 Roadmap.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSBanner() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade700, Colors.red.shade900],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SOSScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emergency,
                        color: Colors.red,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Emergency SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tap for immediate help',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendImSafeSignal,
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  label: const Text('I\'M SAFE', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _sendImSafeSignal() async {
    final emergencyService = context.read<EmergencyService>();
    final meshService = context.read<MeshNetworkService>();

    try {
      await emergencyService.broadcastEmergency(
        senderId: meshService.deviceId ?? 'unknown',
        senderName: meshService.deviceName ?? 'unknown',
        type: SignalType.safe,
        level: EmergencyLevel.low,
        message: 'I am safe - Status check-in',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Safe signal broadcasted to mesh!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send safe signal: $e')),
        );
      }
    }
  }

  Widget _buildConversationList() {
    final conversations = _storageService.getAllConversations();

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button below to start messaging',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return ConversationListItem(
          conversation: conversation,
          onTap: () {
            if (conversation.peerId.startsWith('group_')) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupChatScreen(
                    groupId: conversation.peerId,
                    groupName: conversation.peerName,
                  ),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    peerId: conversation.peerId,
                    peerName: conversation.peerName,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  void _showNewConversationDialog() {
    final meshService = context.read<MeshNetworkService>();
    final peers = meshService.peers;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Conversation'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: peers.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.group_add, color: Colors.white),
                      ),
                      title: const Text('New Group Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text('Create an offline group of 2-50 members'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
                        );
                      },
                    ),
                    const Divider(),
                  ],
                );
              }
              final peer = peers[index - 1];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(peer.name[0].toUpperCase()),
                ),
                title: Text(peer.name),
                subtitle: Text(peer.status.name),
                trailing: Icon(
                  peer.isAvailable ? Icons.circle : Icons.circle_outlined,
                  color: peer.isAvailable ? Colors.green : Colors.grey,
                  size: 12,
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        peerId: peer.id,
                        peerName: peer.name,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    final meshService = context.read<MeshNetworkService>();
    meshService.stopScanning();
    meshService.stopAdvertising();
    super.dispose();
  }
}
