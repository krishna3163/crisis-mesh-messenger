import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/offline_email.dart';
import 'mesh_network_service.dart';

class MeshRoutingService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();
  final MeshNetworkService _meshService;

  Box<OfflineEmail>? _emailBox;
  bool _isGateway = false;

  MeshRoutingService(this._meshService);

  bool get isGateway => _isGateway;

  Future<void> initialize() async {
    _logger.i('Initializing Mesh Routing Service...');
    
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(OfflineEmailAdapter());
    }

    _emailBox = await Hive.openBox<OfflineEmail>('offline_emails');
    _logger.i('Mesh Routing Service initialized with ${_emailBox?.length} emails queued.');
  }

  /// Toggle internet gateway status for the current node
  void setGatewayStatus(bool hasInternet) {
    _isGateway = hasInternet;
    notifyListeners();
    if (_isGateway) {
      _processQueuedEmails();
    }
  }

  /// Select next hop nodes prioritizing Drones, Vehicles, and high-battery standard devices.
  /// Excludes nodes with critical battery (< 15%).
  List<Peer> getBestRelayRoutes() {
    final peers = _meshService.peers;
    final candidates = peers.where((p) => p.isAvailable && p.batteryLevel >= 15).toList();

    candidates.sort((a, b) {
      // 1. Drones (high altitude, high range) first
      // 2. Vehicles (unlimited power grid) second
      // 3. Handheld phones (battery prioritized) third
      final scoreA = _getRelayTypeScore(a.peerType);
      final scoreB = _getRelayTypeScore(b.peerType);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);

      // Prefer higher battery levels among standard nodes
      return b.batteryLevel.compareTo(a.batteryLevel);
    });

    return candidates;
  }

  int _getRelayTypeScore(String type) {
    switch (type.toUpperCase()) {
      case 'DRONE_RELAY':
        return 3;
      case 'VEHICLE_RELAY':
        return 2;
      case 'STANDARD':
      default:
        return 1;
    }
  }

  // --- Offline Email Logic ---
  Future<void> sendOfflineEmail(String recipient, String subject, String body) async {
    final myName = _meshService.deviceName ?? 'Self';
    final emailId = 'email_${_uuid.v4()}';

    final email = OfflineEmail(
      id: emailId,
      senderEmail: '$myName@crisis.mesh',
      recipientEmail: recipient,
      subject: subject,
      body: body,
      status: 'QUEUED',
      timestamp: DateTime.now(),
      routePath: [_meshService.deviceId ?? 'self'],
    );

    await _emailBox?.put(emailId, email);
    notifyListeners();

    // Check if we already have direct access to a gateway
    final gateways = _meshService.peers.where((p) => p.isAvailable && p.isInternetGateway).toList();
    if (gateways.isNotEmpty || _isGateway) {
      await _deliverEmailToInternet(email);
    } else {
      // Forward email to best relay routes over mesh
      await broadcastEmailPayload(email);
    }
  }

  List<OfflineEmail> getEmails() {
    final list = _emailBox?.values.toList();
    if (list == null) return [];
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  Future<void> handleReceivedEmail(OfflineEmail email) async {
    final existing = _emailBox?.get(email.id);
    if (existing != null && existing.status == 'SENT') return; // already sent

    _logger.i('Received offline email via store-and-forward: ${email.subject}');
    await _emailBox?.put(email.id, email.copyWith(status: 'RELAYED'));
    notifyListeners();

    // If this node is a gateway, deliver to internet!
    if (_isGateway) {
      await _deliverEmailToInternet(email);
    } else {
      // Otherwise, forward closer to relays
      final route = List<String>.from(email.routePath)..add(_meshService.deviceId ?? 'unknown');
      final forwarded = email.copyWith(
        hopCount: email.hopCount + 1,
        routePath: route,
      );
      await broadcastEmailPayload(forwarded);
    }
  }

  Future<void> handleReceivedEmailStatus(String emailId, String status) async {
    final email = _emailBox?.get(emailId);
    if (email != null) {
      await _emailBox?.put(emailId, email.copyWith(status: status));
      notifyListeners();
    }
  }

  Future<void> broadcastEmailPayload(OfflineEmail email) async {
    await _meshService.broadcastPayload('email_update', email.toJson());
  }

  Future<void> _deliverEmailToInternet(OfflineEmail email) async {
    _logger.i('Internet connection active. Dispatching offline email to public SMTP: ${email.recipientEmail}');
    
    // Simulate SMTP network call
    await Future.delayed(const Duration(milliseconds: 1500));
    
    await _emailBox?.put(email.id, email.copyWith(status: 'SENT'));
    notifyListeners();

    // Broadcast email status update to clear queue of intermediate relays
    await _meshService.broadcastPayload('email_status_update', {
      'id': email.id,
      'status': 'SENT',
    });
  }

  Future<void> _processQueuedEmails() async {
    if (!_isGateway || _emailBox == null) return;
    final queued = _emailBox!.values.where((e) => e.status == 'QUEUED' || e.status == 'RELAYED').toList();
    for (final email in queued) {
      await _deliverEmailToInternet(email);
    }
  }
}
