import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/offline_email.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_routing_service.dart';

// Mock MeshNetworkService
class FakeMeshNetworkService extends MeshNetworkService {
  @override
  String get deviceId => 'node_local';
  
  @override
  String get deviceName => 'Local Device';

  final List<Peer> mockPeers = [];
  final List<Map<String, dynamic>> sentPayloads = [];

  @override
  List<Peer> get peers => mockPeers;

  @override
  Future<bool> broadcastPayload(String type, Map<String, dynamic> payload, {List<String>? excludeNodeIds}) async {
    sentPayloads.add({'type': type, 'payload': payload});
    return true;
  }
}

void main() {
  late Directory tempDir;
  late FakeMeshNetworkService fakeMesh;
  late MeshRoutingService routingService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_routing_test');
    Hive.init(tempDir.path);

    fakeMesh = FakeMeshNetworkService();
    routingService = MeshRoutingService(fakeMesh);
    await routingService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Battery-Aware Relay selection filters low battery and sorts by type score and battery level', () {
    // Populate fake discovered peers in mesh
    fakeMesh.mockPeers.addAll([
      Peer(id: 'node_1', name: 'User Phone A', lastSeen: DateTime.now(), batteryLevel: 10, peerType: 'STANDARD', status: PeerStatus.nearby), // Critical battery (<15%) -> exclude
      Peer(id: 'node_2', name: 'User Phone B', lastSeen: DateTime.now(), batteryLevel: 80, peerType: 'STANDARD', status: PeerStatus.nearby), // Valid standard
      Peer(id: 'node_3', name: 'Drone Relay X', lastSeen: DateTime.now(), batteryLevel: 40, peerType: 'DRONE_RELAY', status: PeerStatus.nearby), // Drone (prioritized)
      Peer(id: 'node_4', name: 'Rescue Truck Z', lastSeen: DateTime.now(), batteryLevel: 90, peerType: 'VEHICLE_RELAY', status: PeerStatus.nearby), // Vehicle (prioritized)
      Peer(id: 'node_5', name: 'User Phone C', lastSeen: DateTime.now(), batteryLevel: 95, peerType: 'STANDARD', status: PeerStatus.nearby), // High battery standard
    ]);

    final routes = routingService.getBestRelayRoutes();

    // Verification:
    // 1. node_1 (10% battery) must be excluded
    expect(routes.any((p) => p.id == 'node_1'), false);

    // 2. Drone Relay X (type score 3) must be 1st
    expect(routes[0].id, 'node_3');

    // 3. Rescue Truck Z (type score 2) must be 2nd
    expect(routes[1].id, 'node_4');

    // 4. Standard User Phone C (95% battery) must beat Phone B (80% battery)
    expect(routes[2].id, 'node_5');
    expect(routes[3].id, 'node_2');
  });

  test('Store-and-forward offline email drafts and sync status updates', () async {
    fakeMesh.sentPayloads.clear();

    // 1. Send email while offline (no gateway available)
    await routingService.sendOfflineEmail('doctor@redcross.org', 'Urgent medical supplies request', 'We require more saline bags.');

    final queuedEmails = routingService.getEmails();
    expect(queuedEmails.length, 1);
    expect(queuedEmails.first.status, 'QUEUED');

    // Verify broadcast occurred to mesh relays
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'email_update');

    // 2. Simulate entering active gateway zone (internet connection detected)
    routingService.setGatewayStatus(true);

    // Wait for async mock SMTP dispatch
    await Future.delayed(const Duration(milliseconds: 1600));

    final sentEmails = routingService.getEmails();
    expect(sentEmails.first.status, 'SENT');

    // Verify status status update broadcast dispatched to other relays
    expect(fakeMesh.sentPayloads.last['type'], 'email_status_update');
    expect(fakeMesh.sentPayloads.last['payload']['status'], 'SENT');
  });
}
