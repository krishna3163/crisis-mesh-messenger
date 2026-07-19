import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import 'encryption_service.dart';
import 'package:crisis_mesh/core/models/peer.dart';
import 'package:crisis_mesh/core/models/message.dart';
import 'package:crisis_mesh/core/models/emergency_signal.dart';
import 'package:crisis_mesh/core/models/feed_post.dart';
import 'package:crisis_mesh/core/models/feed_comment.dart';
import 'package:crisis_mesh/core/models/channel.dart';
import 'package:crisis_mesh/core/models/channel_message.dart';
import 'package:crisis_mesh/core/services/rescue/emergency_service.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/models/group.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'package:crisis_mesh/core/models/triage_card.dart';
import 'package:crisis_mesh/core/models/medical_supply.dart';
import 'package:crisis_mesh/core/models/rescue_task.dart';
import 'package:crisis_mesh/core/services/rescue/rescue_medical_service.dart';
import 'package:crisis_mesh/core/models/offline_email.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_routing_service.dart';
import 'package:crisis_mesh/core/services/hardware/hardware_sensor_service.dart';
import 'package:crisis_mesh/core/models/market_listing.dart';
import 'package:crisis_mesh/core/models/leader_vote.dart';
import 'package:crisis_mesh/core/services/community/community_service.dart';

/// Service managing the mesh network connections and discovery using Nearby Connections API
class MeshNetworkService extends ChangeNotifier {
  final Logger _logger = Logger();
  final Nearby _nearby = Nearby();
  final EncryptionService _encryptionService = getIt<EncryptionService>();

  // Current state
  final Map<String, Peer> _peers = {};
  final Map<String, DateTime> _lastPeerUpdate = {};
  final Set<String> _processedMessageIds = {}; // For deduplication
  bool _isScanning = false;
  bool _isAdvertising = false;
  String? _deviceId;
  String? _deviceName;
  Timer? _deduplicationTimer;

  // Callbacks
  Function(Message)? onMessageReceived;
  Function(Peer)? onPeerDiscovered;
  Function(String)? onPeerDisconnected;
  Function(String peerId, bool isTyping)? onTypingStatusChanged;
  Function(String messageId, String peerId, MessageStatus status)? onMessageStatusChanged;
  Function(String messageId)? onMessageDeleted;

  // Getters
  List<Peer> get peers => _peers.values.toList();
  List<Peer> get onlinePeers =>
      _peers.values.where((p) => p.status == PeerStatus.online).toList();
  bool get isScanning => _isScanning;
  bool get isAdvertising => _isAdvertising;
  String? get deviceId => _deviceId;
  String? get deviceName => _deviceName;

  /// Initialize the mesh network service
  Future<void> initialize(String deviceId, String deviceName) async {
    _deviceId = deviceId;
    _deviceName = deviceName;
    _logger.i('Mesh network initialized: $deviceName ($deviceId)');

    // Start deduplication cache cleaner
    _deduplicationTimer = Timer.periodic(const Duration(minutes: 30), (_) {
      _processedMessageIds.clear();
    });

    // Check and request permissions
    await _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.bluetoothAdvertise,
        Permission.location,
        Permission.nearbyWifiDevices,
      ].request();

      _logger.i('Permissions status: $status');
    }
  }

  /// Start scanning for nearby peers
  Future<void> startScanning() async {
    if (_isScanning) return;

    _logger.i('Starting peer discovery (Nearby Connections)...');

    try {
      bool success = await _nearby.startDiscovery(
        _deviceId!,
        Strategy.P2P_CLUSTER,
        onEndpointFound: (id, name, serviceId) {
          _logger.i('Endpoint found: $name ($id)');
          final peer = Peer(
            id: id,
            name: name,
            deviceType: 'Nearby Device',
            lastSeen: DateTime.now(),
            status: PeerStatus.nearby,
          );
          _updatePeer(peer);
        },
        onEndpointLost: (id) {
          _logger.i('Endpoint lost: $id');
          final peer = _peers[id];
          if (peer != null) {
            _updatePeer(peer.copyWith(status: PeerStatus.offline));
          }
          onPeerDisconnected?.call(id ?? '');
        },
        serviceId: "com.crisis.mesh",
      );

      if (success) {
        _isScanning = true;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Discovery failed: $e');
    }
  }

  /// Stop scanning for peers
  Future<void> stopScanning() async {
    if (!_isScanning) return;

    _logger.i('Stopping peer discovery...');
    await _nearby.stopDiscovery();
    _isScanning = false;
    notifyListeners();
  }

  /// Start advertising this device
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;

    _logger.i('Starting advertising: $_deviceName');

    try {
      bool success = await _nearby.startAdvertising(
        _deviceName!,
        Strategy.P2P_CLUSTER,
        onConnectionInitiated: (id, info) {
          _logger.i('Connection initiated from $id: ${info.endpointName}');
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) async {
          _logger.i('Connection result for $id: $status');
          if (status == Status.CONNECTED) {
            final peer = _peers[id];
            if (peer != null) {
              _updatePeer(peer.copyWith(status: PeerStatus.online));
            } else {
              _updatePeer(Peer(
                id: id,
                name: "Peer $id", // Default name if not found in discovery
                status: PeerStatus.online,
                lastSeen: DateTime.now(),
              ));
            }
            // Send handshake
            await _sendHandshake(id);
          }
        },
        onDisconnected: (id) {
          _logger.i('Disconnected from $id');
          final peer = _peers[id];
          if (peer != null) {
            _updatePeer(peer.copyWith(status: PeerStatus.offline));
          }
        },
        serviceId: "com.crisis.mesh",
      );

      if (success) {
        _isAdvertising = true;
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Advertising failed: $e');
    }
  }

  /// Stop advertising this device
  Future<void> stopAdvertising() async {
    if (!_isAdvertising) return;

    _logger.i('Stopping advertising');
    await _nearby.stopAdvertising();
    _isAdvertising = false;
    notifyListeners();
  }

  void _acceptConnection(String id) {
    _nearby.acceptConnection(
      id,
      onPayLoadRecieved: (id, payload) async {
        if (payload.type == PayloadType.BYTES) {
          final str = String.fromCharCodes(payload.bytes!);
          _logger.d('Payload received from $id: $str');
          try {
            final json = jsonDecode(str) as Map<String, dynamic>;

            // Check for Handshake (retains backward compatibility / old structure)
            if (json['type'] == 'handshake') {
              _logger.i('Handshake received from $id');
              final publicKey = json['publicKey'] as String;
              await _encryptionService.establishSession(id, publicKey);

              // Update peer trusted status if needed
              final peer = _peers[id];
              if (peer != null) {
                _updatePeer(peer.copyWith(publicKey: publicKey, status: PeerStatus.online));
              }
              return;
            }

            final type = json['type'] as String?;
            if (type == null) {
              // Backward compatibility: raw Message
              final message = Message.fromJson(json);
              _handleReceivedMessage(message);
              return;
            }

            final payloadData = json['payload'] as Map<String, dynamic>;
            switch (type) {
              case 'chat_message':
                final message = Message.fromJson(payloadData);
                _handleReceivedMessage(message);
                break;
              case 'typing_status':
                final senderId = payloadData['senderId'] as String;
                final isTyping = payloadData['isTyping'] as bool;
                onTypingStatusChanged?.call(senderId, isTyping);
                break;
              case 'delivery_receipt':
                final messageId = payloadData['messageId'] as String;
                final senderId = payloadData['senderId'] as String;
                _updateStoredMessageStatus(messageId, MessageStatus.delivered);
                onMessageStatusChanged?.call(messageId, senderId, MessageStatus.delivered);
                break;
              case 'read_receipt':
                final messageId = payloadData['messageId'] as String;
                final senderId = payloadData['senderId'] as String;
                _updateStoredMessageStatus(messageId, MessageStatus.read);
                onMessageStatusChanged?.call(messageId, senderId, MessageStatus.read);
                break;
              case 'delete_message':
                final messageId = payloadData['messageId'] as String;
                final storage = getIt<MessageStorageService>();
                await storage.deleteMessage(messageId);
                onMessageDeleted?.call(messageId);
                break;
              case 'emergency_signal':
                final signal = EmergencySignal.fromJson(payloadData);
                getIt<EmergencyService>().receiveSignal(signal);
                break;
              case 'feed_post':
                final post = FeedPost.fromJson(payloadData);
                getIt<FeedService>().handleReceivedPost(post);
                break;
              case 'feed_like':
                final postId = payloadData['postId'] as String;
                final userId = payloadData['userId'] as String;
                getIt<FeedService>().handleReceivedLike(postId, userId);
                break;
              case 'feed_comment':
                final comment = FeedComment.fromJson(payloadData);
                getIt<FeedService>().handleReceivedComment(comment);
                break;
              case 'channel_meta':
                final channel = Channel.fromJson(payloadData);
                getIt<ChannelService>().handleReceivedChannel(channel);
                break;
              case 'channel_message':
                final channelMsg = ChannelMessage.fromJson(payloadData);
                getIt<ChannelService>().handleReceivedChannelMessage(channelMsg);
                break;
              case 'group_meta':
                final group = Group.fromJson(payloadData);
                getIt<GroupService>().handleReceivedGroupMeta(group);
                break;
              case 'group_message':
                final groupMsg = Message.fromJson(payloadData);
                getIt<GroupService>().handleReceivedGroupMessage(groupMsg);
                break;
              case 'triage_update':
                final card = TriageCard.fromJson(payloadData);
                getIt<RescueMedicalService>().handleReceivedTriage(card);
                break;
              case 'supply_update':
                final supply = MedicalSupply.fromJson(payloadData);
                getIt<RescueMedicalService>().handleReceivedSupply(supply);
                break;
              case 'task_update':
                final task = RescueTask.fromJson(payloadData);
                getIt<RescueMedicalService>().handleReceivedTask(task);
                break;
              case 'email_update':
                final email = OfflineEmail.fromJson(payloadData);
                getIt<MeshRoutingService>().handleReceivedEmail(email);
                break;
              case 'email_status_update':
                final emailId = payloadData['id'] as String;
                final status = payloadData['status'] as String;
                getIt<MeshRoutingService>().handleReceivedEmailStatus(emailId, status);
                break;
              case 'seismic_warning':
                final source = payloadData['source'] as String;
                getIt<HardwareSensorService>().triggerEarthquakeAlert(source: source, broadcast: false);
                break;
              case 'market_update':
                final listing = MarketListing.fromJson(payloadData);
                getIt<CommunityService>().handleReceivedMarketListing(listing);
                break;
              case 'leader_vote':
                final vote = LeaderVote.fromJson(payloadData);
                getIt<CommunityService>().handleReceivedVote(vote);
                break;
              case 'leader_vote_rescind':
                final voterId = payloadData['voterId'] as String;
                getIt<CommunityService>().handleReceivedVoteRescind(voterId);
                break;
              default:
                _logger.w('Unknown payload type: $type');
            }
          } catch (e) {
            _logger.e('Failed to parse received payload: $e');
          }
        }
      },
      onPayloadTransferUpdate: (id, update) {
        // Handle payload transfer updates (useful for large files)
      },
    );
  }

  Future<void> _sendHandshake(String peerId) async {
    final publicKey = await _encryptionService.getPublicKey();
    if (publicKey == null) return;

    final handshake = {
      'type': 'handshake',
      'publicKey': publicKey,
      'senderId': _deviceId,
    };

    final bytes = Uint8List.fromList(jsonEncode(handshake).codeUnits);
    await _nearby.sendBytesPayload(peerId, bytes);
    _logger.i('Handshake sent to $peerId');
  }

  /// Connect to a specific peer
  Future<bool> connectToPeer(String peerId) async {
    _logger.i('Connecting to peer: $peerId');

    final peer = _peers[peerId];
    if (peer == null) {
      _logger.w('Peer not found: $peerId');
      return false;
    }

    _updatePeer(peer.copyWith(status: PeerStatus.connecting));

    try {
      await _nearby.requestConnection(
        _deviceName!,
        peerId,
        onConnectionInitiated: (id, info) {
          _logger.i('Connection initiated to $id: ${info.endpointName}');
          _acceptConnection(id);
        },
        onConnectionResult: (id, status) async {
          _logger.i('Connection result for $id: $status');
          if (status == Status.CONNECTED) {
            _updatePeer(peer.copyWith(status: PeerStatus.online));
            // Send handshake
            await _sendHandshake(id);
          } else {
            _updatePeer(peer.copyWith(status: PeerStatus.offline));
          }
        },
        onDisconnected: (id) {
          _logger.i('Disconnected from $id');
          _updatePeer(peer.copyWith(status: PeerStatus.offline));
        },
      );
      return true;
    } catch (e) {
      _logger.e('Connection request failed: $e');
      _updatePeer(peer.copyWith(status: PeerStatus.offline));
      return false;
    }
  }

  /// Disconnect from a peer
  Future<void> disconnectFromPeer(String peerId) async {
    _logger.i('Disconnecting from peer: $peerId');
    await _nearby.disconnectFromEndpoint(peerId);
    final peer = _peers[peerId];
    if (peer != null) {
      _updatePeer(peer.copyWith(status: PeerStatus.offline));
    }
  }

  /// Send a message through the mesh network
  Future<bool> sendMessage(Message message) async {
    _logger.i('Sending message: ${message.id} to ${message.recipientId}');

    // Try to encrypt if we have a session with the recipient (only for direct messages for now)
    Message finalMessage = message;
    if (message.content.isNotEmpty && message.groupId == null) {
      final cipherText = await _encryptionService.encrypt(message.recipientId, message.content);
      if (cipherText != null) {
        finalMessage = message.copyWith(
          encryptedContent: cipherText,
          isEncrypted: true,
        );
        _logger.d('Message ${message.id} encrypted for recipient ${message.recipientId}');
      }
    }

    // For group messages or if recipient is not direct, broadcast
    final recipient = _peers[finalMessage.recipientId];
    if (finalMessage.groupId == null && recipient?.status == PeerStatus.online) {
      return await _sendDirectMessage(finalMessage, recipient!);
    }

    // Epidemic routing - send to all connected peers
    return await _broadcastMessage(finalMessage);
  }

  /// Send message directly to a connected peer
  Future<bool> _sendDirectMessage(Message message, Peer peer) async {
    final wrapper = {
      'type': 'chat_message',
      'payload': message.toJson(),
    };
    return await _sendRawPayload(peer.id, wrapper);
  }

  /// Send raw payload directly to a peer
  Future<bool> _sendRawPayload(String peerId, Map<String, dynamic> data) async {
    try {
      final jsonStr = jsonEncode(data);
      final bytes = Uint8List.fromList(jsonStr.codeUnits);
      await _nearby.sendBytesPayload(peerId, bytes);
      return true;
    } catch (e) {
      _logger.e('Failed to send payload to $peerId: $e');
      return false;
    }
  }

  /// Broadcast a payload to all connected online peers
  Future<bool> broadcastPayload(String type, Map<String, dynamic> payload, {List<String>? excludeNodeIds}) async {
    final onlinePeersList = onlinePeers;
    if (onlinePeersList.isEmpty) {
      _logger.w('No peers available to broadcast $type');
      return false;
    }

    _logger.i('Broadcasting payload of type $type to ${onlinePeersList.length} peers');

    final wrapper = {
      'type': type,
      'payload': payload,
    };

    int successCount = 0;
    for (final peer in onlinePeersList) {
      if (excludeNodeIds != null && excludeNodeIds.contains(peer.id)) {
        continue;
      }
      if (await _sendRawPayload(peer.id, wrapper)) {
        successCount++;
      }
    }

    return successCount > 0;
  }

  /// Broadcast message to all connected peers (epidemic routing)
  Future<bool> _broadcastMessage(Message message) async {
    if (!message.canForward) {
      _logger.w('Message has reached max hops: ${message.id}');
      return false;
    }

    final onlinePeersList = onlinePeers;
    if (onlinePeersList.isEmpty) {
      _logger.w('No peers available to relay message');
      return false;
    }

    _logger.i('Broadcasting message to ${onlinePeersList.length} peers');

    int successCount = 0;
    for (final peer in onlinePeersList) {
      final forwarded = message.incrementHop(_deviceId!);
      if (await _sendDirectMessage(forwarded, peer)) {
        successCount++;
      }
    }

    return successCount > 0;
  }

  /// Handle received message
  void _handleReceivedMessage(Message message) async {
    // Deduplication check
    if (_processedMessageIds.contains(message.id)) {
      _logger.d('Message ${message.id} already processed, skipping.');
      return;
    }
    _processedMessageIds.add(message.id);

    _logger.i('Received message: ${message.id} from ${message.senderId}');

    // Check if message is for us
    if (message.recipientId == _deviceId) {
      _logger.i('Message is for us!');

      Message finalMessage = message;
      if (message.isEncrypted && message.encryptedContent != null) {
        final clearText = await _encryptionService.decrypt(message.senderId, message.encryptedContent!);
        if (clearText != null) {
          finalMessage = message.copyWith(content: clearText);
          _logger.d('Message ${message.id} decrypted successfully.');
        } else {
          _logger.w('Failed to decrypt message ${message.id}. Might be missing session key.');
        }
      }

      // Automatically save to Hive and update conversation
      try {
        final storage = getIt<MessageStorageService>();
        await storage.saveMessage(finalMessage);
        
        final peerName = _peers[finalMessage.senderId]?.name ?? 'User';
        await storage.updateConversationWithMessage(finalMessage, _deviceId!, peerName);
      } catch (e) {
        _logger.e('Failed to auto-save received message: $e');
      }

      // Send delivery receipt back immediately
      sendDeliveryReceipt(finalMessage.id, finalMessage.senderId);

      onMessageReceived?.call(finalMessage);
      return;
    }

    // Forward the message if it can still hop
    if (message.canForward) {
      _logger.i('Forwarding message: ${message.id}');
      _broadcastMessage(message);
    } else {
      _logger.w('Message reached max hops, dropping: ${message.id}');
    }
  }

  /// Update or add a peer
  void _updatePeer(Peer peer) {
    final existing = _peers[peer.id];
    if (existing == null) {
      _logger.i('New peer discovered: ${peer.name} (${peer.id})');
      _peers[peer.id] = peer;
      onPeerDiscovered?.call(peer);
    } else {
      _peers[peer.id] = peer;
    }

    _lastPeerUpdate[peer.id] = DateTime.now();
    notifyListeners();
  }

  void _updateStoredMessageStatus(String messageId, MessageStatus status) {
    try {
      final storage = getIt<MessageStorageService>();
      final message = storage.getMessage(messageId);
      if (message != null) {
        final updated = message.copyWith(status: status);
        storage.saveMessage(updated);
      }
    } catch (e) {
      _logger.e('Failed to update message status in Hive: $e');
    }
  }

  /// Send typing status to a specific recipient
  void sendTypingStatus(String recipientId, bool isTyping) {
    final payload = {
      'senderId': _deviceId,
      'isTyping': isTyping,
    };
    final wrapper = {
      'type': 'typing_status',
      'payload': payload,
    };
    
    final recipient = _peers[recipientId];
    if (recipient != null && recipient.status == PeerStatus.online) {
      _sendRawPayload(recipient.id, wrapper);
    }
  }

  /// Send delivery receipt to a specific recipient
  void sendDeliveryReceipt(String messageId, String recipientId) {
    final payload = {
      'messageId': messageId,
      'senderId': _deviceId,
    };
    final wrapper = {
      'type': 'delivery_receipt',
      'payload': payload,
    };
    
    final recipient = _peers[recipientId];
    if (recipient != null && recipient.status == PeerStatus.online) {
      _sendRawPayload(recipient.id, wrapper);
    }
  }

  /// Send read receipt to a specific recipient
  void sendReadReceipt(String messageId, String recipientId) {
    final payload = {
      'messageId': messageId,
      'senderId': _deviceId,
    };
    final wrapper = {
      'type': 'read_receipt',
      'payload': payload,
    };
    
    final recipient = _peers[recipientId];
    if (recipient != null && recipient.status == PeerStatus.online) {
      _sendRawPayload(recipient.id, wrapper);
    }
  }

  /// Send remote delete event to a specific recipient
  void sendRemoteDelete(String messageId, String recipientId) {
    final payload = {
      'messageId': messageId,
      'senderId': _deviceId,
    };
    
    final recipient = _peers[recipientId];
    if (recipient != null && recipient.status == PeerStatus.online) {
      final wrapper = {
        'type': 'delete_message',
        'payload': payload,
      };
      _sendRawPayload(recipient.id, wrapper);
    } else {
      // If offline, broadcast to mesh so it relays to them eventually
      broadcastPayload('delete_message', payload);
    }
  }

  @override
  void dispose() {
    stopScanning();
    stopAdvertising();
    _deduplicationTimer?.cancel();
    _nearby.stopAllEndpoints();
    _peers.clear();
    _lastPeerUpdate.clear();
    _processedMessageIds.clear();
    super.dispose();
  }
}
