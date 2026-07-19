import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'rescue_task.g.dart';

@HiveType(typeId: 12)
class RescueTask extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String priority; // 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'

  @HiveField(4)
  final double? latitude;

  @HiveField(5)
  final double? longitude;

  @HiveField(6)
  final String? assignedTeamId;

  @HiveField(7)
  final String status; // 'OPEN', 'ASSIGNED', 'IN_PROGRESS', 'COMPLETED'

  @HiveField(8)
  final DateTime timestamp;

  const RescueTask({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.latitude,
    this.longitude,
    this.assignedTeamId,
    required this.status,
    required this.timestamp,
  });

  RescueTask copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    double? latitude,
    double? longitude,
    String? assignedTeamId,
    String? status,
    DateTime? timestamp,
  }) {
    return RescueTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      assignedTeamId: assignedTeamId ?? this.assignedTeamId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'priority': priority,
        'latitude': latitude,
        'longitude': longitude,
        'assignedTeamId': assignedTeamId,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RescueTask.fromJson(Map<String, dynamic> json) => RescueTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        priority: json['priority'] as String,
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
        assignedTeamId: json['assignedTeamId'] as String?,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priority,
        latitude,
        longitude,
        assignedTeamId,
        status,
        timestamp,
      ];
}
