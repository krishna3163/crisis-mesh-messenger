import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'medical_profile.g.dart';

@HiveType(typeId: 10)
class MedicalProfile extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bloodGroup;

  @HiveField(3)
  final List<String> allergies;

  @HiveField(4)
  final List<String> conditions;

  @HiveField(5)
  final List<String> medications;

  @HiveField(6)
  final String emergencyContactName;

  @HiveField(7)
  final String emergencyContactPhone;

  @HiveField(8)
  final String emergencyContactRelation;

  @HiveField(9)
  final bool isOrganDonor;

  @HiveField(10)
  final String pregnancyStatus;

  @HiveField(11)
  final String notes;

  const MedicalProfile({
    required this.id,
    required this.name,
    required this.bloodGroup,
    required this.allergies,
    required this.conditions,
    required this.medications,
    required this.emergencyContactName,
    required this.emergencyContactPhone,
    required this.emergencyContactRelation,
    this.isOrganDonor = false,
    this.pregnancyStatus = 'N/A',
    this.notes = '',
  });

  MedicalProfile copyWith({
    String? id,
    String? name,
    String? bloodGroup,
    List<String>? allergies,
    List<String>? conditions,
    List<String>? medications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    bool? isOrganDonor,
    String? pregnancyStatus,
    String? notes,
  }) {
    return MedicalProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bloodGroup': bloodGroup,
        'allergies': allergies,
        'conditions': conditions,
        'medications': medications,
        'emergencyContactName': emergencyContactName,
        'emergencyContactPhone': emergencyContactPhone,
        'emergencyContactRelation': emergencyContactRelation,
        'isOrganDonor': isOrganDonor,
        'pregnancyStatus': pregnancyStatus,
        'notes': notes,
      };

  factory MedicalProfile.fromJson(Map<String, dynamic> json) => MedicalProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        bloodGroup: json['bloodGroup'] as String,
        allergies: (json['allergies'] as List).cast<String>(),
        conditions: (json['conditions'] as List).cast<String>(),
        medications: (json['medications'] as List).cast<String>(),
        emergencyContactName: json['emergencyContactName'] as String,
        emergencyContactPhone: json['emergencyContactPhone'] as String,
        emergencyContactRelation: json['emergencyContactRelation'] as String,
        isOrganDonor: json['isOrganDonor'] as bool? ?? false,
        pregnancyStatus: json['pregnancyStatus'] as String? ?? 'N/A',
        notes: json['notes'] as String? ?? '',
      );

  @override
  List<Object?> get props => [
        id,
        name,
        bloodGroup,
        allergies,
        conditions,
        medications,
        emergencyContactName,
        emergencyContactPhone,
        emergencyContactRelation,
        isOrganDonor,
        pregnancyStatus,
        notes,
      ];
}
