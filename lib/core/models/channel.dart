import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'channel.g.dart';

@HiveType(typeId: 6)
class Channel extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String creatorId;

  @HiveField(4)
  final bool isPublic;

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final int membersCount;

  const Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    this.isPublic = true,
    required this.timestamp,
    this.membersCount = 1,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? description,
    String? creatorId,
    bool? isPublic,
    DateTime? timestamp,
    int? membersCount,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId ?? this.creatorId,
      isPublic: isPublic ?? this.isPublic,
      timestamp: timestamp ?? this.timestamp,
      membersCount: membersCount ?? this.membersCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'creatorId': creatorId,
        'isPublic': isPublic,
        'timestamp': timestamp.toIso8601String(),
        'membersCount': membersCount,
      };

  factory Channel.fromJson(Map<String, dynamic> json) {
    return Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      isPublic: json['isPublic'] as bool? ?? true,
      timestamp: DateTime.parse(json['timestamp'] as String),
      membersCount: json['membersCount'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [id, name, description, creatorId, isPublic, timestamp, membersCount];
}
