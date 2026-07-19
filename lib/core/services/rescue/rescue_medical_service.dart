import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/medical_profile.dart';
import 'package:crisis_mesh/core/models/triage_card.dart';
import 'package:crisis_mesh/core/models/rescue_task.dart';
import 'package:crisis_mesh/core/models/medical_supply.dart';
import 'package:crisis_mesh/core/models/landing_zone.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

class RescueMedicalService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();
  final MeshNetworkService _meshService;

  Box<MedicalProfile>? _profileBox;
  Box<TriageCard>? _triageBox;
  Box<RescueTask>? _taskBox;
  Box<MedicalSupply>? _supplyBox;
  Box<LandingZone>? _lzBox;

  RescueMedicalService(this._meshService);

  Future<void> initialize() async {
    _logger.i('Initializing Rescue & Medical Service...');

    // Register Hive Adapters
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(MedicalProfileAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(TriageCardAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(RescueTaskAdapter());
    if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(MedicalSupplyAdapter());
    if (!Hive.isAdapterRegistered(14)) Hive.registerAdapter(LandingZoneAdapter());

    // Open Boxes
    _profileBox = await Hive.openBox<MedicalProfile>('medical_profiles');
    _triageBox = await Hive.openBox<TriageCard>('triage_cards');
    _taskBox = await Hive.openBox<RescueTask>('rescue_tasks');
    _supplyBox = await Hive.openBox<MedicalSupply>('medical_supplies');
    _lzBox = await Hive.openBox<LandingZone>('landing_zones');

    // Populate initial default medical supplies list if empty
    if (_supplyBox!.isEmpty) {
      await _prepopulateSupplies();
    }

    _logger.i('Rescue & Medical Service initialized successfully.');
  }

  Future<void> _prepopulateSupplies() async {
    final list = [
      MedicalSupply(id: 'sup_1', name: 'First Aid Kit (Type A)', category: 'FIRST_AID', quantity: 15, unit: 'kits', lowStockThreshold: 5, timestamp: DateTime.now()),
      MedicalSupply(id: 'sup_2', name: 'Oxygen Cylinder (10L)', category: 'OXYGEN', quantity: 4, unit: 'cylinders', lowStockThreshold: 2, timestamp: DateTime.now()),
      MedicalSupply(id: 'sup_3', name: 'Bandages Sterile', category: 'FIRST_AID', quantity: 50, unit: 'packs', lowStockThreshold: 10, timestamp: DateTime.now()),
      MedicalSupply(id: 'sup_4', name: 'Amoxicillin 500mg', category: 'MEDICINE', quantity: 100, unit: 'vials', lowStockThreshold: 20, timestamp: DateTime.now()),
      MedicalSupply(id: 'sup_5', name: 'Blood O-Negative', category: 'BLOOD', quantity: 2, unit: 'bags', lowStockThreshold: 3, timestamp: DateTime.now()),
    ];
    for (final item in list) {
      await _supplyBox?.put(item.id, item);
    }
  }

  // --- Medical Profile Logic ---
  Future<void> saveProfile(MedicalProfile profile) async {
    await _profileBox?.put(profile.id, profile);
    notifyListeners();
  }

  List<MedicalProfile> getProfiles() {
    return _profileBox?.values.toList() ?? [];
  }

  MedicalProfile? getProfile(String id) {
    return _profileBox?.get(id);
  }

  // --- Digital Triage Cards Logic ---
  Future<void> saveTriageCard(TriageCard card, {bool broadcast = true}) async {
    await _triageBox?.put(card.id, card);
    notifyListeners();

    if (broadcast) {
      await _meshService.broadcastPayload('triage_update', card.toJson());
    }
  }

  List<TriageCard> getTriageCards() {
    final list = _triageBox?.values.toList();
    if (list == null) return [];
    list.sort((a, b) {
      // Prioritize status RED, then YELLOW, then GREEN, then BLACK
      final scoreA = _getStatusPriorityScore(a.status);
      final scoreB = _getStatusPriorityScore(b.status);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return b.timestamp.compareTo(a.timestamp);
    });
    return list;
  }

  int _getStatusPriorityScore(String status) {
    switch (status.toUpperCase()) {
      case 'RED':
        return 4;
      case 'YELLOW':
        return 3;
      case 'GREEN':
        return 2;
      case 'BLACK':
        return 1;
      default:
        return 0;
    }
  }

  TriageCard? getTriageCard(String id) {
    return _triageBox?.get(id);
  }

  // --- Rescue Task Queue Logic ---
  Future<void> saveRescueTask(RescueTask task, {bool broadcast = true}) async {
    await _taskBox?.put(task.id, task);
    notifyListeners();

    if (broadcast) {
      await _meshService.broadcastPayload('task_update', task.toJson());
    }
  }

  List<RescueTask> getRescueTasks() {
    final list = _taskBox?.values.toList();
    if (list == null) return [];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // --- Supply Inventory Tracker ---
  Future<void> saveSupply(MedicalSupply supply, {bool broadcast = true}) async {
    await _supplyBox?.put(supply.id, supply);
    notifyListeners();

    if (broadcast) {
      await _meshService.broadcastPayload('supply_update', supply.toJson());
    }
  }

  List<MedicalSupply> getSupplies() {
    return _supplyBox?.values.toList() ?? [];
  }

  // --- Landing Zone Evaluator ---
  Future<void> saveLandingZone(LandingZone lz) async {
    await _lzBox?.put(lz.id, lz);
    notifyListeners();
  }

  List<LandingZone> getLandingZones() {
    final list = _lzBox?.values.toList();
    if (list == null) return [];
    list.sort((a, b) => b.score.compareTo(a.score));
    return list;
  }

  /// Score landing site (0 to 100) based on slope, dimensions, and surface suitability
  double calculateLandingZoneScore(double slope, String surfaceType, double sizeMeters) {
    // 1. Slope suitability (max standard helicopter limit is 15 degrees)
    double slopeScore = 0.0;
    if (slope <= 15) {
      slopeScore = 100 - (slope * 6.66); // 0 deg = 100 pts, 15 deg = 0 pts
    }

    // 2. Dimension suitability (requires at least 15m; optimal is 25m or larger)
    double sizeScore = 0.0;
    if (sizeMeters >= 15) {
      if (sizeMeters >= 25) {
        sizeScore = 100;
      } else {
        sizeScore = (sizeMeters - 15) * 10; // Linear scaling 15m to 25m
      }
    }

    // 3. Surface suitability
    double surfaceMultiplier = 0.5;
    switch (surfaceType.toUpperCase()) {
      case 'CONCRETE':
      case 'ASPHALT':
        surfaceMultiplier = 1.0;
        break;
      case 'GRASS':
        surfaceMultiplier = 0.9;
        break;
      case 'DIRT':
        surfaceMultiplier = 0.75;
        break;
      case 'SAND':
      case 'OTHER':
      default:
        surfaceMultiplier = 0.5;
        break;
    }

    final finalScore = (slopeScore * 0.5 + sizeScore * 0.5) * surfaceMultiplier;
    return finalScore.clamp(0.0, 100.0);
  }

  // --- Mesh Sync Signal Handlers ---
  Future<void> handleReceivedTriage(TriageCard incomingCard) async {
    final existing = _triageBox?.get(incomingCard.id);
    if (existing != null && existing.timestamp.isAfter(incomingCard.timestamp)) {
      return; // local is newer
    }

    _logger.i('Synced triage update for patient: ${incomingCard.patientName}');
    await _triageBox?.put(incomingCard.id, incomingCard);
    notifyListeners();
  }

  Future<void> handleReceivedSupply(MedicalSupply incomingSupply) async {
    final existing = _supplyBox?.get(incomingSupply.id);
    if (existing != null && existing.timestamp.isAfter(incomingSupply.timestamp)) {
      return; // local is newer
    }

    _logger.i('Synced supply updates: ${incomingSupply.name}');
    await _supplyBox?.put(incomingSupply.id, incomingSupply);
    notifyListeners();
  }

  Future<void> handleReceivedTask(RescueTask incomingTask) async {
    final existing = _taskBox?.get(incomingTask.id);
    if (existing != null && existing.timestamp.isAfter(incomingTask.timestamp)) {
      return; // local is newer
    }

    _logger.i('Synced rescue task update: ${incomingTask.title}');
    await _taskBox?.put(incomingTask.id, incomingTask);
    notifyListeners();
  }
}
