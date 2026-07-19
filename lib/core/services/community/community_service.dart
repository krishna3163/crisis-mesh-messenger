import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/market_listing.dart';
import 'package:crisis_mesh/core/models/leader_vote.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class CommunityService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();
  final MeshNetworkService _meshService;

  Box<MarketListing>? _marketBox;
  Box<LeaderVote>? _voteBox;

  // Cache of reputation points: volunteer ID -> points
  final Map<String, int> _reputationPoints = {};
  final Map<String, int> _resolvedCounts = {};

  CommunityService(this._meshService);

  Future<void> initialize() async {
    _logger.i('Initializing Community Service...');

    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(MarketListingAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(LeaderVoteAdapter());
    }

    _marketBox = await Hive.openBox<MarketListing>('market_listings');
    _voteBox = await Hive.openBox<LeaderVote>('leader_votes');

    _logger.i('Community Service initialized with ${_marketBox?.length} listings and ${_voteBox?.length} votes.');
  }

  // --- Volunteer Reputation Metrics ---
  void awardReputation(String peerId, int points, {bool isTaskResolution = false}) {
    final current = _reputationPoints[peerId] ?? 0;
    _reputationPoints[peerId] = current + points;

    if (isTaskResolution) {
      final currentRes = _resolvedCounts[peerId] ?? 0;
      _resolvedCounts[peerId] = currentRes + 1;
    }

    notifyListeners();
  }

  int getReputationPoints(String peerId) {
    return _reputationPoints[peerId] ?? 0;
  }

  int getResolvedCount(String peerId) {
    return _resolvedCounts[peerId] ?? 0;
  }

  String getBadgeLevel(String peerId) {
    final pts = getReputationPoints(peerId);
    if (pts >= 600) return 'Gold Responder';
    if (pts >= 300) return 'Silver Responder';
    if (pts >= 100) return 'Bronze Responder';
    return 'Community Helper';
  }

  // --- Barter Marketplace ---
  Future<void> addMarketListing(
    String title,
    String desc,
    String type,
    String cat,
    double qty,
    String unit,
  ) async {
    final listId = 'listing_${_uuid.v4()}';
    final myId = _meshService.deviceId ?? 'self';
    final myName = _meshService.deviceName ?? 'Self';

    final listing = MarketListing(
      id: listId,
      title: title,
      description: desc,
      listingType: type,
      category: cat,
      quantity: qty,
      unit: unit,
      creatorId: myId,
      creatorName: myName,
      status: 'ACTIVE',
      timestamp: DateTime.now(),
    );

    await _marketBox?.put(listId, listing);
    notifyListeners();

    // Broadcast update across mesh
    await _meshService.broadcastPayload('market_update', listing.toJson());
  }

  List<MarketListing> getListings() {
    return _marketBox?.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp)) ?? [];
  }

  Future<void> handleReceivedMarketListing(MarketListing listing) async {
    _logger.i('Received marketplace barter listing update: ${listing.title}');
    await _marketBox?.put(listing.id, listing);
    notifyListeners();
  }

  // --- Neighborhood Leader Election ---
  Future<void> castVote(String nomineeId, String nomineeName) async {
    final myId = _meshService.deviceId ?? 'self';
    final myName = _meshService.deviceName ?? 'Self';

    // Remove any previous vote cast by this voter
    final oldVotes = _voteBox?.values.where((v) => v.voterId == myId).toList();
    if (oldVotes != null) {
      for (final v in oldVotes) {
        await _voteBox?.delete(v.id);
      }
    }

    final voteId = 'vote_${_uuid.v4()}';
    final vote = LeaderVote(
      id: voteId,
      nomineeId: nomineeId,
      nomineeName: nomineeName,
      voterId: myId,
      voterName: myName,
      timestamp: DateTime.now(),
    );

    await _voteBox?.put(voteId, vote);
    notifyListeners();

    // Broadcast election vote over mesh
    await _meshService.broadcastPayload('leader_vote', vote.toJson());
  }

  Future<void> rescindVote() async {
    final myId = _meshService.deviceId ?? 'self';
    final oldVotes = _voteBox?.values.where((v) => v.voterId == myId).toList();
    if (oldVotes != null) {
      for (final v in oldVotes) {
        await _voteBox?.delete(v.id);
      }
    }
    notifyListeners();

    await _meshService.broadcastPayload('leader_vote_rescind', {'voterId': myId});
  }

  LeaderVote? getMyVote() {
    final myId = _meshService.deviceId ?? 'self';
    final votes = _voteBox?.values.where((v) => v.voterId == myId).toList();
    return (votes != null && votes.isNotEmpty) ? votes.first : null;
  }

  Map<String, int> getVoteTallies() {
    final tallies = <String, int>{};
    if (_voteBox == null) return tallies;

    for (final vote in _voteBox!.values) {
      tallies[vote.nomineeId] = (tallies[vote.nomineeId] ?? 0) + 1;
    }
    return tallies;
  }

  Future<void> handleReceivedVote(LeaderVote vote) async {
    // Prevent double voting from incoming mesh node updates
    final oldVotes = _voteBox?.values.where((v) => v.voterId == vote.voterId).toList();
    if (oldVotes != null) {
      for (final v in oldVotes) {
        await _voteBox?.delete(v.id);
      }
    }

    await _voteBox?.put(vote.id, vote);
    notifyListeners();
  }

  Future<void> handleReceivedVoteRescind(String voterId) async {
    final oldVotes = _voteBox?.values.where((v) => v.voterId == voterId).toList();
    if (oldVotes != null) {
      for (final v in oldVotes) {
        await _voteBox?.delete(v.id);
      }
    }
    notifyListeners();
  }
}
