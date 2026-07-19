import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/market_listing.dart';
import 'package:crisis_mesh/core/models/leader_vote.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';

// Mock MeshNetworkService
class FakeMeshNetworkService extends MeshNetworkService {
  @override
  String get deviceId => 'voter_local';
  @override
  String get deviceName => 'Local Voter';

  final List<Map<String, dynamic>> sentPayloads = [];

  @override
  Future<bool> broadcastPayload(String type, Map<String, dynamic> payload, {List<String>? excludeNodeIds}) async {
    sentPayloads.add({'type': type, 'payload': payload});
    return true;
  }
}

void main() {
  late Directory tempDir;
  late FakeMeshNetworkService fakeMesh;
  late CommunityService communityService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('community_test');
    Hive.init(tempDir.path);

    fakeMesh = FakeMeshNetworkService();
    communityService = CommunityService(fakeMesh);
    await communityService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Volunteer Reputation levels scale up correctly based on points', () {
    const peerId = 'responder_alpha';

    // 1. Initial level
    expect(communityService.getReputationPoints(peerId), 0);
    expect(communityService.getBadgeLevel(peerId), 'Community Helper');

    // 2. Award 150 points -> Bronze Responder
    communityService.awardReputation(peerId, 150);
    expect(communityService.getBadgeLevel(peerId), 'Bronze Responder');

    // 3. Award another 200 points (total 350) -> Silver Responder
    communityService.awardReputation(peerId, 200, isTaskResolution: true);
    expect(communityService.getBadgeLevel(peerId), 'Silver Responder');
    expect(communityService.getResolvedCount(peerId), 1);

    // 4. Award another 300 points (total 650) -> Gold Responder
    communityService.awardReputation(peerId, 300);
    expect(communityService.getBadgeLevel(peerId), 'Gold Responder');
  });

  test('Barter Marketplace lists item and broadcasts update', () async {
    fakeMesh.sentPayloads.clear();

    await communityService.addMarketListing('Gasoline canister', 'Full 5L container of unleaded petrol', 'OFFER', 'Fuel', 1.0, 'canister');

    final listings = communityService.getListings();
    expect(listings.length, 1);
    expect(listings.first.title, 'Gasoline canister');
    expect(listings.first.category, 'Fuel');

    // Check broadcast update sent over Nearby Connections mesh
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'market_update');
    expect(fakeMesh.sentPayloads.first['payload']['title'], 'Gasoline canister');
  });

  test('Leader Elections prevents double voting and computes tallies correctly', () async {
    fakeMesh.sentPayloads.clear();

    // Nominees
    const candidate1 = 'candidate_bob';
    const candidate2 = 'candidate_alice';

    // 1. Local user votes for Candidate 1
    await communityService.castVote(candidate1, 'Bob');
    var tallies = communityService.getVoteTallies();
    expect(tallies[candidate1], 1);
    expect(tallies[candidate2], null);

    // Verify broadcast occurred
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'leader_vote');

    // 2. Local user changes mind and votes for Candidate 2
    await communityService.castVote(candidate2, 'Alice');
    tallies = communityService.getVoteTallies();

    // Verify double-voting is blocked (Bob vote deleted, Alice vote is 1)
    expect(tallies[candidate1], 0); // or removed
    expect(tallies[candidate2], 1);
    expect(communityService.getMyVote()?.nomineeId, candidate2);

    // 3. Receive incoming mesh votes from other peers
    await communityService.handleReceivedVote(const LeaderVote(
      id: 'vote_peer1',
      nomineeId: candidate1,
      nomineeName: 'Bob',
      voterId: 'peer_node_1',
      voterName: 'Peer 1',
      timestamp: null, // manual
    ));

    await communityService.handleReceivedVote(const LeaderVote(
      id: 'vote_peer2',
      nomineeId: candidate1,
      nomineeName: 'Bob',
      voterId: 'peer_node_2',
      voterName: 'Peer 2',
      timestamp: null, // manual
    ));

    tallies = communityService.getVoteTallies();
    expect(tallies[candidate1], 2);
    expect(tallies[candidate2], 1);
  });
}

// Stub timestamp helper
extension on LeaderVote {
  DateTime get timestamp => DateTime.now();
}
