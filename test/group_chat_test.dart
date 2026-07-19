import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crisis_mesh/core/di/service_locator.dart';
import 'package:crisis_mesh/core/models/group.dart';
import 'package:crisis_mesh/core/models/message.dart';
import 'package:crisis_mesh/core/models/conversation.dart';
import 'package:crisis_mesh/core/services/messaging/group_service.dart';
import 'package:crisis_mesh/core/services/messaging/message_storage_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

// Mock MeshNetworkService
class FakeMeshService extends MeshNetworkService {
  @override
  String get deviceId => 'creator_device_id';
  
  @override
  String get deviceName => 'Creator Device';

  final List<Map<String, dynamic>> sentPayloads = [];

  @override
  Future<bool> broadcastPayload(String type, Map<String, dynamic> payload, {List<String>? excludeNodeIds}) async {
    sentPayloads.add({'type': type, 'payload': payload});
    return true;
  }
}

void main() {
  late Directory tempDir;
  late FakeMeshService fakeMesh;
  late GroupService groupService;
  late MessageStorageService storageService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crisis_group_test');
    Hive.init(tempDir.path);

    fakeMesh = FakeMeshService();
    storageService = MessageStorageService();
    await storageService.initialize();

    // Register storage service in getIt since GroupService depends on it
    if (getIt.isRegistered<MessageStorageService>()) {
      await getIt.unregister<MessageStorageService>();
    }
    getIt.registerSingleton<MessageStorageService>(storageService);

    groupService = GroupService(fakeMesh);
    await groupService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('Group serialization supports standard JSON representation', () {
    final original = Group(
      id: 'group_123',
      name: 'Rescue Team Delta',
      avatar: 'avatar_url',
      creatorId: 'alice',
      memberIds: const ['alice', 'bob', 'charlie'],
      adminIds: const ['alice'],
      timestamp: DateTime(2026, 7, 19, 12, 0),
    );

    final json = original.toJson();
    expect(json['id'], 'group_123');
    expect(json['name'], 'Rescue Team Delta');
    expect(json['avatar'], 'avatar_url');
    expect(json['memberIds'], ['alice', 'bob', 'charlie']);

    final parsed = Group.fromJson(json);
    expect(parsed.id, 'group_123');
    expect(parsed.name, 'Rescue Team Delta');
    expect(parsed.memberIds, ['alice', 'bob', 'charlie']);
    expect(parsed.adminIds, ['alice']);
  });

  test('GroupService should create groups, save metadata, and broadcast payloads', () async {
    // 1. Create Group
    final groupId = await groupService.createGroup('Sector 4 Rescuers', ['bob', 'charlie']);
    expect(groupId.startsWith('group_'), true);

    final group = groupService.getGroup(groupId);
    expect(group, isNotNull);
    expect(group!.name, 'Sector 4 Rescuers');
    expect(group.memberIds.contains('creator_device_id'), true);
    expect(group.memberIds.contains('bob'), true);

    // Verify metadata broadcast payload was sent
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'group_meta');

    // Verify conversation was created
    final conversation = storageService.getConversationByPeer(groupId);
    expect(conversation, isNotNull);
    expect(conversation!.peerName, 'Sector 4 Rescuers');
  });

  test('GroupService should handle group message sending, local saving, and relaying', () async {
    final groupId = await groupService.createGroup('Neighborhood Watch', ['bob']);
    fakeMesh.sentPayloads.clear(); // Clear create broadcast

    // Send group message
    await groupService.sendGroupMessage(groupId, 'Safe check-in: all clear.');

    // Verify local storage
    final messages = storageService.getMessagesForConversation(groupId, 'creator_device_id');
    expect(messages.length, 1);
    expect(messages.first.content, 'Safe check-in: all clear.');
    expect(messages.first.groupId, groupId);

    // Verify network broadcast
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'group_message');
  });

  test('GroupService should process incoming group metadata and relay it', () async {
    final incomingGroup = Group(
      id: 'group_999',
      name: 'External Medical Unit',
      creatorId: 'bob',
      memberIds: const ['bob', 'creator_device_id'],
      adminIds: const ['bob'],
      timestamp: DateTime.now(),
    );

    // Receive metadata
    await groupService.handleReceivedGroupMeta(incomingGroup);

    final group = groupService.getGroup('group_999');
    expect(group, isNotNull);
    expect(group!.name, 'External Medical Unit');

    // Verify relay broadcast
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'group_meta');
  });
}
