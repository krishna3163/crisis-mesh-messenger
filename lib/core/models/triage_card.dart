import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'triage_card.g.dart';

@HiveType(typeId: 11)
class TriageCard extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String patientName;

  @HiveField(2)
  final String status; // 'RED', 'YELLOW', 'GREEN', 'BLACK'

  @HiveField(3)
  final List<String> injuries;

  @HiveField(4)
  final int heartRate;

  @HiveField(5)
  final String bloodPressure;

  @HiveField(6)
  final double temperature;

  @HiveField(7)
  final double? latitude;

  @HiveField(8)
  final double? longitude;

  @HiveField(9)
  final String? assignedTeamId;

  @HiveField(10)
  final bool isResolved;

  @HiveField(11)
  final DateTime timestamp;

  const TriageCard({
    required this.id,
    required this.patientName,
    required this.status,
    required this.injuries,
    required this.heartRate,
    required this.bloodPressure,
    required this.temperature,
    this.latitude,
    this.longitude,
    this.assignedTeamId,
    this.isResolved = false,
    required this.timestamp,
  });

  TriageCard copyWith({
    String? id,
    String? patientName,
    String? status,
    List<String>? injuries,
    int? heartRate,
    String? bloodPressure,
    double? temperature,
    double? latitude,
    double? longitude,
    String? assignedTeamId,
    bool? isResolved,
    DateTime? timestamp,
  }) {
    return TriageCard(
      id: id ?? this.id,
      patientName: patientName ?? this.patientName,
      status: status ?? this.status,
      injuries: injuries ?? this.injuries,
      heartRate: heartRate ?? this.heartRate,
      bloodPressure: bloodPressure ?? this.bloodPressure,
      temperature: temperature ?? this.temperature,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      assignedTeamId: assignedTeamId ?? this.assignedTeamId,
      isResolved: isResolved ?? this.isResolved,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientName': patientName,
        'status': status,
        'injuries': injuries,
        'heartRate': heartRate,
        'bloodPressure': bloodPressure,
        'temperature': temperature,
        'latitude': latitude,
        'longitude': longitude,
        'assignedTeamId': assignedTeamId,
        'isResolved': isResolved,
        'timestamp': timestamp.toIso8601String(),
      };

  factory TriageCard.fromJson(Map<String, dynamic> json) => TriageCard(
        id: json['id'] as String,
        patientName: json['patientName'] as String,
        status: json['status'] as String,
        injuries: (json['injuries'] as List).cast<String>(),
        heartRate: json['heartRate'] as int,
        bloodPressure: json['bloodPressure'] as String,
        temperature: (json['temperature'] as num).toDouble(),
        latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
        longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
        assignedTeamId: json['assignedTeamId'] as String?,
        isResolved: json['isResolved'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        patientName,
        status,
        injuries,
        heartRate,
        bloodPressure,
        temperature,
        latitude,
        longitude,
        assignedTeamId,
        isResolved,
        timestamp,
      ];
}
