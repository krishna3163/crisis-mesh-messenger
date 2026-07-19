import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'market_listing.g.dart';

@HiveType(typeId: 16)
class MarketListing extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String listingType; // 'OFFER', 'REQUEST'

  @HiveField(4)
  final String category; // 'Food', 'Water', 'Meds', 'Fuel', 'Gear', 'Other'

  @HiveField(5)
  final double quantity;

  @HiveField(6)
  final String unit;

  @HiveField(7)
  final String creatorId;

  @HiveField(8)
  final String creatorName;

  @HiveField(9)
  final String status; // 'ACTIVE', 'MATCHED', 'COMPLETED'

  @HiveField(10)
  final DateTime timestamp;

  const MarketListing({
    required this.id,
    required this.title,
    required this.description,
    required this.listingType,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.creatorId,
    required this.creatorName,
    required this.status,
    required this.timestamp,
  });

  MarketListing copyWith({
    String? id,
    String? title,
    String? description,
    String? listingType,
    String? category,
    double? quantity,
    String? unit,
    String? creatorId,
    String? creatorName,
    String? status,
    DateTime? timestamp,
  }) {
    return MarketListing(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      listingType: listingType ?? this.listingType,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'listingType': listingType,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'creatorId': creatorId,
        'creatorName': creatorName,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      };

  factory MarketListing.fromJson(Map<String, dynamic> json) => MarketListing(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        listingType: json['listingType'] as String,
        category: json['category'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String,
        creatorId: json['creatorId'] as String,
        creatorName: json['creatorName'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        listingType,
        category,
        quantity,
        unit,
        creatorId,
        creatorName,
        status,
        timestamp,
      ];
}
