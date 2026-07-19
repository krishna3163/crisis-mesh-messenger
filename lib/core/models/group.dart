import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'group.g.dart';

/// Represents a group chat in the mesh network
@HiveType(typeId: 9)
class Group extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String? avatar;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final List<String> memberIds;

  @HiveField(5)
  final List<String> adminIds;

  @HiveField(6)
  final DateTime timestamp;

  const Group({
    required this.id,
    required this.name,
    this.avatar,
    required this.creatorId,
    required this.memberIds,
    required this.adminIds,
    required this.timestamp,
  });

  Group copyWith({
    String? id,
    String? name,
    String? avatar,
    String? creatorId,
    List<String>? memberIds,
    List<String>? adminIds,
    DateTime? timestamp,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      creatorId: creatorId ?? this.creatorId,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'creatorId': creatorId,
        'memberIds': memberIds,
        'adminIds': adminIds,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Group.fromJson(Map<String, dynamic> json) => Group(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String?,
        creatorId: json['creatorId'] as String,
        memberIds: (json['memberIds'] as List).cast<String>(),
        adminIds: (json['adminIds'] as List).cast<String>(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        avatar,
        creatorId,
        memberIds,
        adminIds,
        timestamp,
      ];
}
