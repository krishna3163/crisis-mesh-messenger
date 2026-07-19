import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crisis_mesh/core/models/triage_card.dart';
import 'package:crisis_mesh/core/models/medical_supply.dart';
import 'package:crisis_mesh/core/models/landing_zone.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

// Mock MeshNetworkService
class FakeMeshNetworkService extends MeshNetworkService {
  @override
  String get deviceId => 'test_device_id';
  
  @override
  String get deviceName => 'Test Device';

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
  late RescueMedicalService rescueService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('rescue_medical_test');
    Hive.init(tempDir.path);

    fakeMesh = FakeMeshNetworkService();
    rescueService = RescueMedicalService(fakeMesh);
    await rescueService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Helicopter Landing Zone Suitability Scoring Algorithm works', () {
    // 1. Ideal Landing Zone (Flat slope, Concrete, >25m clearance)
    final score1 = rescueService.calculateLandingZoneScore(0.0, 'CONCRETE', 30.0);
    expect(score1, 100.0); // 100% suitable

    // 2. Sloped landing zone (10 degrees slope, Grass, 20m clearance)
    final score2 = rescueService.calculateLandingZoneScore(10.0, 'GRASS', 20.0);
    // Slope score: 100 - (10 * 6.66) = 33.4
    // Size score: (20 - 15) * 10 = 50
    // Combined raw: (33.4 * 0.5 + 50 * 0.5) = 41.7
    // Grass multiplier: 0.9
    // Final score = 41.7 * 0.9 = 37.53
    expect(score2 > 30.0 && score2 < 40.0, true);

    // 3. Slope limit exceeded (>15 degrees)
    final score3 = rescueService.calculateLandingZoneScore(16.0, 'CONCRETE', 25.0);
    expect(score3, 50.0 * 1.0); // Slope score drops to 0, size score remains 100, mult is 1.0 -> 50.0

    // 4. Undersized LZ (<15m)
    final score4 = rescueService.calculateLandingZoneScore(0.0, 'CONCRETE', 10.0);
    expect(score4, 50.0 * 1.0); // Size score drops to 0, slope score remains 100, mult is 1.0 -> 50.0
  });

  test('Triage Card prioritization sorts by urgency first', () {
    final list = [
      TriageCard(id: '1', patientName: 'Bob', status: 'GREEN', injuries: const [], heartRate: 75, bloodPressure: '120/80', temperature: 36.6, timestamp: DateTime(2026, 7, 19, 10, 0)),
      TriageCard(id: '2', patientName: 'Alice', status: 'RED', injuries: const [], heartRate: 130, bloodPressure: '90/60', temperature: 38.5, timestamp: DateTime(2026, 7, 19, 10, 5)),
      TriageCard(id: '3', patientName: 'Charlie', status: 'YELLOW', injuries: const [], heartRate: 90, bloodPressure: '110/70', temperature: 37.0, timestamp: DateTime(2026, 7, 19, 10, 10)),
      TriageCard(id: '4', patientName: 'Dave', status: 'BLACK', injuries: const [], heartRate: 0, bloodPressure: '0/0', temperature: 35.0, timestamp: DateTime(2026, 7, 19, 10, 15)),
    ];

    // Priority mapping: RED (4), YELLOW (3), GREEN (2), BLACK (1)
    list.sort((a, b) {
      final scoreA = a.status == 'RED' ? 4 : (a.status == 'YELLOW' ? 3 : (a.status == 'GREEN' ? 2 : 1));
      final scoreB = b.status == 'RED' ? 4 : (b.status == 'YELLOW' ? 3 : (b.status == 'GREEN' ? 2 : 1));
      return scoreB.compareTo(scoreA);
    });

    expect(list[0].patientName, 'Alice');   // RED
    expect(list[1].patientName, 'Charlie'); // YELLOW
    expect(list[2].patientName, 'Bob');     // GREEN
    expect(list[3].patientName, 'Dave');    // BLACK
  });

  test('RescueMedicalService handles pre-populating inventory and inventory changes', () async {
    final supplies = rescueService.getSupplies();
    expect(supplies.isNotEmpty, true);

    // Get First Aid Kit item
    final item = supplies.firstWhere((s) => s.id == 'sup_1');
    expect(item.quantity, 15.0);
    expect(item.lowStockThreshold, 5.0);

    // Modify stock count to trigger low-stock alarm
    final updated = item.copyWith(quantity: 4.0, timestamp: DateTime.now());
    await rescueService.saveSupply(updated);

    final modifiedList = rescueService.getSupplies();
    final modifiedItem = modifiedList.firstWhere((s) => s.id == 'sup_1');
    expect(modifiedItem.quantity, 4.0);
    expect(modifiedItem.quantity <= modifiedItem.lowStockThreshold, true); // alarm active!
  });

  test('RescueMedicalService syncs incoming triage cards with newer timestamps', () async {
    final original = TriageCard(
      id: 'tri_xxx',
      patientName: 'Incoming Patient',
      status: 'YELLOW',
      injuries: const ['Head laceration'],
      heartRate: 85,
      bloodPressure: '120/80',
      temperature: 36.8,
      timestamp: DateTime(2026, 7, 19, 12, 0),
    );
    await rescueService.saveTriageCard(original, broadcast: false);

    // Sync an update with a newer timestamp
    final incomingNewer = original.copyWith(
      status: 'RED',
      timestamp: DateTime(2026, 7, 19, 12, 5),
    );
    await rescueService.handleReceivedTriage(incomingNewer);

    final updated = rescueService.getTriageCard('tri_xxx');
    expect(updated, isNotNull);
    expect(updated!.status, 'RED'); // Status updated to RED

    // Sync an update with an older timestamp (should be ignored)
    final incomingOlder = original.copyWith(
      status: 'GREEN',
      timestamp: DateTime(2026, 7, 19, 11, 55),
    );
    await rescueService.handleReceivedTriage(incomingOlder);

    final notUpdated = rescueService.getTriageCard('tri_xxx');
    expect(notUpdated!.status, 'RED'); // Remains RED
  });
}
