import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import '../../models/group.dart';
import '../../models/message.dart';
import '../../models/conversation.dart';
import '../mesh/mesh_network_service.dart';
import 'message_storage_service.dart';

/// Service managing group creation, updates, messages, and mesh routing
class GroupService extends ChangeNotifier {
  final Logger _logger = Logger();
  final _uuid = const Uuid();

  static const String _groupsBoxName = 'groups';

  Box<Group>? _groupsBox;
  final MeshNetworkService _meshService;

  // Real-time group message callback for active group chat UI
  Function(Message)? onGroupMessageReceived;

  GroupService(this._meshService);

  Future<void> initialize() async {
    _logger.i('Initializing Group service...');

    if (!Hive.isAdapterRegistered(9)) {
      Hive.registerAdapter(GroupAdapter());
    }

    _groupsBox = await Hive.openBox<Group>(_groupsBoxName);
    _logger.i('Group service initialized with ${_groupsBox?.length} groups.');
  }

  /// Create a new group
  Future<String> createGroup(String name, List<String> initialMembers) async {
    final groupId = 'group_${_uuid.v4()}';
    final deviceId = _meshService.deviceId ?? 'unknown';

    // Add creator to member list
    final members = Set<String>.from(initialMembers)..add(deviceId);

    final group = Group(
      id: groupId,
      name: name,
      creatorId: deviceId,
      memberIds: members.toList(),
      adminIds: [deviceId],
      timestamp: DateTime.now(),
    );

    await _groupsBox?.put(groupId, group);

    // Create a conversation for the group in storage
    final storage = getIt<MessageStorageService>();
    final conversation = Conversation(
      id: 'conv_$groupId',
      peerId: groupId,
      peerName: name,
      lastMessageTime: DateTime.now(),
      lastMessagePreview: 'Group created',
      unreadCount: 0,
    );
    await storage.saveConversation(conversation);

    notifyListeners();

    // Broadcast group metadata to peers
    await broadcastGroupMetadata(group);

    return groupId;
  }

  /// Send a message to a group
  Future<void> sendGroupMessage(String groupId, String content) async {
    final messageId = _uuid.v4();
    final deviceId = _meshService.deviceId ?? 'unknown';

    final message = Message(
      id: messageId,
      senderId: deviceId,
      recipientId: groupId,
      content: content,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
      groupId: groupId,
    );

    final storage = getIt<MessageStorageService>();
    await storage.saveMessage(message);
    
    final group = _groupsBox?.get(groupId);
    final groupName = group?.name ?? 'Group';
    await storage.updateConversationWithMessage(message, deviceId, groupName);

    notifyListeners();

    // Broadcast message to peers
    await _broadcastGroupMessage(message);
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    final group = _groupsBox?.get(groupId);
    if (group == null) return;

    final deviceId = _meshService.deviceId ?? 'unknown';
    final updatedMembers = List<String>.from(group.memberIds)..remove(deviceId);
    final updatedAdmins = List<String>.from(group.adminIds)..remove(deviceId);

    final updatedGroup = group.copyWith(
      memberIds: updatedMembers,
      adminIds: updatedAdmins,
    );

    await _groupsBox?.put(groupId, updatedGroup);
    
    // Delete conversation locally
    final storage = getIt<MessageStorageService>();
    await storage.deleteConversation('conv_$groupId');
    
    notifyListeners();

    // Broadcast updated group details
    await broadcastGroupMetadata(updatedGroup);
  }

  /// Add member to a group
  Future<void> addGroupMember(String groupId, String memberId) async {
    final group = _groupsBox?.get(groupId);
    if (group == null) return;

    final deviceId = _meshService.deviceId ?? 'unknown';
    if (!group.adminIds.contains(deviceId)) {
      _logger.w('Only admins can add members.');
      return;
    }

    if (group.memberIds.contains(memberId)) return;

    final updatedMembers = List<String>.from(group.memberIds)..add(memberId);
    final updatedGroup = group.copyWith(memberIds: updatedMembers);

    await _groupsBox?.put(groupId, updatedGroup);
    notifyListeners();

    await broadcastGroupMetadata(updatedGroup);
  }

  /// Remove member from a group
  Future<void> removeGroupMember(String groupId, String memberId) async {
    final group = _groupsBox?.get(groupId);
    if (group == null) return;

    final deviceId = _meshService.deviceId ?? 'unknown';
    if (!group.adminIds.contains(deviceId)) {
      _logger.w('Only admins can remove members.');
      return;
    }

    final updatedMembers = List<String>.from(group.memberIds)..remove(memberId);
    final updatedAdmins = List<String>.from(group.adminIds)..remove(memberId);
    final updatedGroup = group.copyWith(
      memberIds: updatedMembers,
      adminIds: updatedAdmins,
    );

    await _groupsBox?.put(groupId, updatedGroup);
    notifyListeners();

    await broadcastGroupMetadata(updatedGroup);
  }

  /// Make member an admin
  Future<void> makeMemberAdmin(String groupId, String memberId) async {
    final group = _groupsBox?.get(groupId);
    if (group == null) return;

    final deviceId = _meshService.deviceId ?? 'unknown';
    if (!group.adminIds.contains(deviceId)) {
      _logger.w('Only admins can make other members admins.');
      return;
    }

    if (group.adminIds.contains(memberId)) return;

    final updatedAdmins = List<String>.from(group.adminIds)..add(memberId);
    final updatedGroup = group.copyWith(adminIds: updatedAdmins);

    await _groupsBox?.put(groupId, updatedGroup);
    notifyListeners();

    await broadcastGroupMetadata(updatedGroup);
  }

  /// Get list of groups joined by the user
  List<Group> getJoinedGroups() {
    if (_groupsBox == null) return [];
    final deviceId = _meshService.deviceId ?? 'unknown';

    return _groupsBox!.values
        .where((group) => group.memberIds.contains(deviceId))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get group details by ID
  Group? getGroup(String groupId) {
    return _groupsBox?.get(groupId);
  }

  /// Handle received group metadata from mesh
  Future<void> handleReceivedGroupMeta(Group group) async {
    final existing = _groupsBox?.get(group.id);
    if (existing != null && existing.timestamp.isAfter(group.timestamp)) {
      // Keep newer local group details
      return;
    }

    _logger.i('Received group metadata: ${group.name} (${group.id})');
    await _groupsBox?.put(group.id, group);

    // If we are a member, ensure conversation exists in database
    final deviceId = _meshService.deviceId ?? 'unknown';
    if (group.memberIds.contains(deviceId)) {
      final storage = getIt<MessageStorageService>();
      var conversation = storage.getConversationByPeer(group.id);
      if (conversation == null) {
        conversation = Conversation(
          id: 'conv_${group.id}',
          peerId: group.id,
          peerName: group.name,
          lastMessageTime: DateTime.now(),
          lastMessagePreview: 'Joined group',
          unreadCount: 0,
        );
        await storage.saveConversation(conversation);
      }
    }

    notifyListeners();

    // Relay to other peers in the mesh
    await broadcastGroupMetadata(group);
  }

  /// Handle received group message from mesh
  Future<void> handleReceivedGroupMessage(Message message) async {
    final groupId = message.groupId;
    if (groupId == null) return;

    _logger.i('Received group message for group $groupId');

    final deviceId = _meshService.deviceId ?? 'unknown';
    final group = _groupsBox?.get(groupId);

    // If we are a member of this group, save it locally and update the conversation
    if (group != null && group.memberIds.contains(deviceId)) {
      final storage = getIt<MessageStorageService>();
      await storage.saveMessage(message);
      await storage.updateConversationWithMessage(message, deviceId, group.name);
      onGroupMessageReceived?.call(message);
    }

    notifyListeners();

    // Forward the message to other nodes in the mesh (epidemic routing)
    if (message.canForward) {
      await _broadcastGroupMessage(message);
    }
  }

  /// Broadcast group metadata to peers
  Future<void> broadcastGroupMetadata(Group group) async {
    _logger.d('Broadcasting group metadata ${group.id}');
    await _meshService.broadcastPayload('group_meta', group.toJson());
  }

  /// Broadcast group message to peers
  Future<void> _broadcastGroupMessage(Message message) async {
    _logger.d('Broadcasting group message ${message.id}');
    final deviceId = _meshService.deviceId ?? 'unknown';
    final forwarded = message.incrementHop(deviceId);
    await _meshService.broadcastPayload('group_message', forwarded.toJson());
  }
}
