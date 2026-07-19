import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';

class ElectionTab extends StatelessWidget {
  const ElectionTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meshService = context.watch<MeshNetworkService>();
    final communityService = context.watch<CommunityService>();
    
    final nominees = meshService.peers.where((p) => p.isAvailable).toList();
    final tallies = communityService.getVoteTallies();
    final myVote = communityService.getMyVote();

    // Determine current elected leader
    String? topNomineeName;
    int topVotes = 0;
    tallies.forEach((id, count) {
      if (count > topVotes) {
        topVotes = count;
        // Search nominee name
        final nom = nominees.firstWhere((p) => p.id == id, orElse: () => nominees.isNotEmpty ? nominees.first : responderSelf(meshService));
        topNomineeName = nom.name;
      }
    });

    return Scaffold(
      body: Column(
        children: [
          // 1. Leaderboard / Current Elected Coordinator Banner
          Container(
            color: theme.colorScheme.primaryContainer.withOpacity(0.4),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.stars, color: theme.colorScheme.primary, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Neighborhood Coordinator Polls',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        topNomineeName != null
                            ? 'Current Leader: $topNomineeName ($topVotes votes)'
                            : 'No coordinator elected yet. Cast votes below.',
                        style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (myVote != null)
                  TextButton.icon(
                    onPressed: () {
                      communityService.rescindVote();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Rescind'),
                  ),
              ],
            ),
          ),
          
          // 2. Nominees List
          Expanded(
            child: nominees.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.how_to_vote_outlined, size: 64, color: theme.colorScheme.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        const Text(
                          'No nearby candidates discovered to nominate.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: nominees.length,
                    itemBuilder: (context, index) {
                      final candidate = nominees[index];
                      final voteCount = tallies[candidate.id] ?? 0;
                      final isMySelection = myVote?.nomineeId == candidate.id;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isMySelection ? BorderSide(color: theme.colorScheme.primary, width: 2) : BorderSide.none,
                        ),
                        child: ListTile(
                          title: Text(candidate.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('ID: ${candidate.id.substring(0, mathMin(candidate.id.length, 12))}...'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$voteCount Votes',
                                  style: TextStyle(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  isMySelection ? Icons.check_circle : Icons.check_circle_outline,
                                  color: isMySelection ? Colors.green : Colors.grey,
                                ),
                                onPressed: () {
                                  communityService.castVote(candidate.id, candidate.name);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  int mathMin(int a, int b) => a < b ? a : b;

  dynamic responderSelf(MeshNetworkService mesh) {
    return dynamic; // fallback
  }
}
