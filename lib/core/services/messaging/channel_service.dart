import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import '../../models/channel.dart';
import '../../models/channel_message.dart';
import '../mesh/mesh_network_service.dart';

class ChannelService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  static const String _channelsBoxName = 'channels';
  static const String _messagesBoxName = 'channel_messages';

  Box<Channel>? _channelsBox;
  Box<ChannelMessage>? _messagesBox;

  // Track joined channel IDs in memory or Hive. Let's store subscription status in a separate list/Hive box or dynamically.
  // For simplicity, we can keep a box for subscription status or just check if user is a member/subscribed.
  // Let's keep a Box of subscribed channel IDs:
  static const String _subsBoxName = 'channel_subscriptions';
  Box<String>? _subsBox;

  final MeshNetworkService _meshService;

  ChannelService(this._meshService);

  Future<void> initialize() async {
    _logger.i('Initializing Channel service...');

    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(ChannelAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(ChannelMessageAdapter());
    }

    _channelsBox = await Hive.openBox<Channel>(_channelsBoxName);
    _messagesBox = await Hive.openBox<ChannelMessage>(_messagesBoxName);
    _subsBox = await Hive.openBox<String>(_subsBoxName);

    _logger.i('Channel service initialized with ${_channelsBox?.length} channels and ${_messagesBox?.length} messages.');
  }

  /// Create a new channel
  Future<void> createChannel(String name, String description, bool isPublic) async {
    final channelId = _uuid.v4();
    final deviceId = _meshService.deviceId ?? 'unknown';

    final channel = Channel(
      id: channelId,
      name: name,
      description: description,
      creatorId: deviceId,
      isPublic: isPublic,
      timestamp: DateTime.now(),
      membersCount: 1,
    );

    await _channelsBox?.put(channelId, channel);
    await joinChannel(channelId); // Join automatically

    // Broadcast the new channel metadata over the mesh
    await broadcastChannelMetadata(channel);
  }

  /// Join a channel
  Future<void> joinChannel(String channelId) async {
    await _subsBox?.put(channelId, channelId);
    notifyListeners();
  }

  /// Leave a channel
  Future<void> leaveChannel(String channelId) async {
    await _subsBox?.delete(channelId);
    notifyListeners();
  }

  /// Check if joined
  bool isJoined(String channelId) {
    return _subsBox?.containsKey(channelId) ?? false;
  }

  /// Send a message in a channel
  Future<void> sendChannelMessage(String channelId, String content) async {
    final messageId = _uuid.v4();
    final deviceId = _meshService.deviceId ?? 'unknown';
    final deviceName = _meshService.deviceName ?? 'My Device';

    final message = ChannelMessage(
      id: messageId,
      channelId: channelId,
      senderId: deviceId,
      senderName: deviceName,
      content: content,
      timestamp: DateTime.now(),
      hopCount: 0,
      routePath: [deviceId],
    );

    await _messagesBox?.put(messageId, message);
    notifyListeners();

    // Broadcast message over mesh
    await _broadcastChannelMessage(message);
  }

  /// Get list of channels joined by the user
  List<Channel> getJoinedChannels() {
    if (_channelsBox == null) return [];
    return _channelsBox!.values
        .where((channel) => isJoined(channel.id))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get list of discoverable public channels that user hasn't joined yet
  List<Channel> getDiscoverableChannels() {
    if (_channelsBox == null) return [];
    return _channelsBox!.values
        .where((channel) => !isJoined(channel.id) && channel.isPublic)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get messages in a channel
  List<ChannelMessage> getChannelMessages(String channelId) {
    if (_messagesBox == null) return [];
    return _messagesBox!.values
        .where((msg) => msg.channelId == channelId)
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Handle received channel metadata from mesh
  Future<void> handleReceivedChannel(Channel channel) async {
    if (_channelsBox?.containsKey(channel.id) ?? false) {
      // Update metadata (e.g. member count) if it's newer, or skip
      return;
    }

    _logger.i('Received channel metadata: ${channel.name}');
    await _channelsBox?.put(channel.id, channel);
    notifyListeners();

    // Relay to other peers
    await broadcastChannelMetadata(channel);
  }

  /// Handle received channel message from mesh
  Future<void> handleReceivedChannelMessage(ChannelMessage message) async {
    if (_messagesBox?.containsKey(message.id) ?? false) return;

    _logger.i('Received channel message for channel ${message.channelId}');
    await _messagesBox?.put(message.id, message);
    notifyListeners();

    // Relay the message if hop limit not exceeded
    if (message.hopCount < 10) {
      await _broadcastChannelMessage(message);
    }
  }

  /// Broadcast channel metadata to peers
  Future<void> broadcastChannelMetadata(Channel channel) async {
    _logger.d('Broadcasting channel metadata ${channel.id}');
    await _meshService.broadcastPayload('channel_meta', channel.toJson());
  }

  /// Broadcast channel message to peers
  Future<void> _broadcastChannelMessage(ChannelMessage message) async {
    _logger.d('Broadcasting channel message ${message.id}');
    final deviceId = _meshService.deviceId ?? 'unknown';
    final forwarded = message.incrementHop(deviceId);
    await _meshService.broadcastPayload('channel_message', forwarded.toJson());
  }
}
