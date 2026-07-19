import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'landing_zone.g.dart';

@HiveType(typeId: 14)
class LandingZone extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double latitude;

  @HiveField(3)
  final double longitude;

  @HiveField(4)
  final double slope; // In degrees

  @HiveField(5)
  final String surfaceType; // 'GRASS', 'CONCRETE', 'ASPHALT', 'DIRT', 'OTHER'

  @HiveField(6)
  final double sizeMeters;

  @HiveField(7)
  final double score; // 0 to 100 calculated suitability score

  @HiveField(8)
  final bool isMarked;

  @HiveField(9)
  final DateTime timestamp;

  const LandingZone({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.slope,
    required this.surfaceType,
    required this.sizeMeters,
    required this.score,
    this.isMarked = false,
    required this.timestamp,
  });

  LandingZone copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? slope,
    String? surfaceType,
    double? sizeMeters,
    double? score,
    bool? isMarked,
    DateTime? timestamp,
  }) {
    return LandingZone(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      slope: slope ?? this.slope,
      surfaceType: surfaceType ?? this.surfaceType,
      sizeMeters: sizeMeters ?? this.sizeMeters,
      score: score ?? this.score,
      isMarked: isMarked ?? this.isMarked,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'slope': slope,
        'surfaceType': surfaceType,
        'sizeMeters': sizeMeters,
        'score': score,
        'isMarked': isMarked,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LandingZone.fromJson(Map<String, dynamic> json) => LandingZone(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        slope: (json['slope'] as num).toDouble(),
        surfaceType: json['surfaceType'] as String,
        sizeMeters: (json['sizeMeters'] as num).toDouble(),
        score: (json['score'] as num).toDouble(),
        isMarked: json['isMarked'] as bool? ?? false,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        latitude,
        longitude,
        slope,
        surfaceType,
        sizeMeters,
        score,
        isMarked,
        timestamp,
      ];
}
