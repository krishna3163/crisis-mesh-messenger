import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:crisis_mesh/core/models/channel.dart';
import 'package:crisis_mesh/core/models/channel_message.dart';
import 'package:crisis_mesh/core/models/feed_post.dart';
import 'package:crisis_mesh/core/models/feed_comment.dart';
import 'package:crisis_mesh/core/services/messaging/feed_service.dart';
import 'package:crisis_mesh/core/services/messaging/channel_service.dart';
import 'package:crisis_mesh/core/services/mesh/mesh_network_service.dart';

// Simple mock for MeshNetworkService
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
  late FeedService feedService;
  late ChannelService channelService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('crisis_mesh_test');
    Hive.init(tempDir.path);

    fakeMesh = FakeMeshNetworkService();
    feedService = FeedService(fakeMesh);
    channelService = ChannelService(fakeMesh);

    await feedService.initialize();
    await channelService.initialize();
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('FeedService should create, like, comment, and broadcast posts', () async {
    // 1. Create post
    await feedService.createPost('Alice', 'Hello Crisis Mesh community!');
    final posts = feedService.getAllPosts();
    expect(posts.length, 1);
    expect(posts.first.content, 'Hello Crisis Mesh community!');
    expect(posts.first.authorName, 'Alice');

    // Verify broadcast payload was sent
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'feed_post');

    // 2. Toggle like
    final postId = posts.first.id;
    await feedService.toggleLike(postId);
    final postsAfterLike = feedService.getAllPosts();
    expect(postsAfterLike.first.likedBy.contains('test_device_id'), true);
    expect(fakeMesh.sentPayloads.length, 2);
    expect(fakeMesh.sentPayloads.last['type'], 'feed_like');

    // 3. Add comment
    await feedService.addComment(postId, 'Bob', 'Stay safe Alice!');
    final comments = feedService.getCommentsForPost(postId);
    expect(comments.length, 1);
    expect(comments.first.content, 'Stay safe Alice!');
    expect(comments.first.authorName, 'Bob');
    expect(fakeMesh.sentPayloads.length, 3);
    expect(fakeMesh.sentPayloads.last['type'], 'feed_comment');
  });

  test('ChannelService should create, join, send message, and broadcast channels', () async {
    // 1. Create channel
    await channelService.createChannel('General Alert', 'Official broadcasts', true);
    final joined = channelService.getJoinedChannels();
    expect(joined.length, 1);
    expect(joined.first.name, 'General Alert');

    // Verify broadcast
    expect(fakeMesh.sentPayloads.length, 1);
    expect(fakeMesh.sentPayloads.first['type'], 'channel_meta');

    // 2. Send channel message
    final channelId = joined.first.id;
    await channelService.sendChannelMessage(channelId, 'Attention: Flood warning in sector 4!');
    final messages = channelService.getChannelMessages(channelId);
    expect(messages.length, 1);
    expect(messages.first.content, 'Attention: Flood warning in sector 4!');
    expect(fakeMesh.sentPayloads.length, 2);
    expect(fakeMesh.sentPayloads.last['type'], 'channel_message');
  });
}
