import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';

class VolunteerTab extends StatelessWidget {
  const VolunteerTab({super.key});

  Color _getBadgeColor(String level) {
    switch (level) {
      case 'Gold Responder':
        return Colors.amber.shade700;
      case 'Silver Responder':
        return Colors.grey.shade600;
      case 'Bronze Responder':
        return Colors.brown.shade600;
      case 'Community Helper':
      default:
        return Colors.blue.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meshService = context.watch<MeshNetworkService>();
    final communityService = context.watch<CommunityService>();
    final peers = meshService.peers;

    return Scaffold(
      body: peers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No volunteer responders discovered yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: peers.length,
              itemBuilder: (context, index) {
                final responder = peers[index];
                final points = communityService.getReputationPoints(responder.id);
                final resolved = communityService.getResolvedCount(responder.id);
                final badge = communityService.getBadgeLevel(responder.id);
                final badgeColor = _getBadgeColor(badge);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(Icons.person, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(responder.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: badgeColor, width: 1),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.military_tech, size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text('$points Points'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.task_alt, size: 16, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('$resolved Tasks Done'),
                            ],
                          ),
                          Row(
                            children: [
                              const Icon(Icons.battery_std, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${responder.batteryLevel}%'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
