import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'medical_supply.g.dart';

@HiveType(typeId: 13)
class MedicalSupply extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String category; // 'MEDICINE', 'OXYGEN', 'BLOOD', 'FIRST_AID', 'OTHER'

  @HiveField(3)
  final double quantity;

  @HiveField(4)
  final String unit;

  @HiveField(5)
  final double lowStockThreshold;

  @HiveField(6)
  final DateTime timestamp;

  const MedicalSupply({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.lowStockThreshold,
    required this.timestamp,
  });

  MedicalSupply copyWith({
    String? id,
    String? name,
    String? category,
    double? quantity,
    String? unit,
    double? lowStockThreshold,
    DateTime? timestamp,
  }) {
    return MedicalSupply(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'lowStockThreshold': lowStockThreshold,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MedicalSupply.fromJson(Map<String, dynamic> json) => MedicalSupply(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        lowStockThreshold: (json['lowStockThreshold'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        quantity,
        unit,
        lowStockThreshold,
        timestamp,
      ];
}
