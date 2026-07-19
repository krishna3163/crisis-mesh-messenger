import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/models/group.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';

class GroupDetailsScreen extends StatelessWidget {
  final String groupId;

  const GroupDetailsScreen({
    required this.groupId,
    super.key,
  });

  String _getUserName(BuildContext context, String userId) {
    final meshService = context.read<MeshNetworkService>();
    if (userId == meshService.deviceId) return '${meshService.deviceName ?? 'You'} (You)';

    final peer = meshService.peers.firstWhere(
      (p) => p.id == userId,
      orElse: () => const MeshNetworkService().peers.isEmpty ? null : null, // dummy
    );
    if (peer != null) return peer.name;

    return 'Node ${userId.substring(0, userId.length > 5 ? 5 : userId.length)}';
  }

  void _showAddMemberDialog(BuildContext context, Group group) {
    final meshService = context.read<MeshNetworkService>();
    final groupService = context.read<GroupService>();
    
    // Peers who are not already members of this group
    final addablePeers = meshService.peers
        .where((peer) => !group.memberIds.contains(peer.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Group Member'),
        content: addablePeers.isEmpty
            ? const Text('No nearby discoverable devices that are not already in the group.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: addablePeers.length,
                  itemBuilder: (context, index) {
                    final peer = addablePeers[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(peer.name[0].toUpperCase()),
                      ),
                      title: Text(peer.name),
                      subtitle: Text(peer.status.name),
                      onTap: () async {
                        Navigator.pop(context);
                        await groupService.addGroupMember(group.id, peer.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${peer.name} added to group!')),
                        );
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _leaveGroup(BuildContext context, GroupService groupService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Group'),
        content: const Text('Are you sure you want to leave this group? You will no longer receive group messages.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await groupService.leaveGroup(groupId);
              if (context.mounted) {
                // Navigate back to Home
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meshService = context.watch<MeshNetworkService>();
    final groupService = context.watch<GroupService>();
    final group = groupService.getGroup(groupId);

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Group Details')),
        body: const Center(child: Text('Group not found')),
      );
    }

    final myDeviceId = meshService.deviceId ?? '';
    final isMeAdmin = group.adminIds.contains(myDeviceId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Group Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    group.name[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  group.name,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created on ${group.timestamp.toString().substring(0, 10)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Members (${group.memberIds.length})',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isMeAdmin)
                TextButton.icon(
                  onPressed: () => _showAddMemberDialog(context, group),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Member'),
                ),
            ],
          ),
          const Divider(),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.memberIds.length,
            itemBuilder: (context, index) {
              final memberId = group.memberIds[index];
              final memberName = _getUserName(context, memberId);
              final isAdmin = group.adminIds.contains(memberId);
              final isCreator = group.creatorId == memberId;

              return ListTile(
                leading: CircleAvatar(
                  child: Text(memberName[0].toUpperCase()),
                ),
                title: Text(memberName),
                subtitle: isCreator
                    ? const Text('Creator & Admin')
                    : (isAdmin ? const Text('Admin') : null),
                trailing: isMeAdmin && memberId != myDeviceId
                    ? PopupMenuButton<String>(
                        onSelected: (action) async {
                          if (action == 'make_admin') {
                            await groupService.makeMemberAdmin(groupId, memberId);
                          } else if (action == 'remove') {
                            await groupService.removeGroupMember(groupId, memberId);
                          }
                        },
                        itemBuilder: (context) => [
                          if (!isAdmin)
                            const PopupMenuItem(
                              value: 'make_admin',
                              child: Text('Make Admin'),
                            ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove from Group', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _leaveGroup(context, groupService),
            icon: const Icon(Icons.exit_to_app, color: Colors.white),
            label: const Text('Leave Group', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
