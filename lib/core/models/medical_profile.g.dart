// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicalProfileAdapter extends TypeAdapter<MedicalProfile> {
  @override
  final int typeId = 10;

  @override
  MedicalProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      bloodGroup: fields[2] as String,
      allergies: (fields[3] as List).cast<String>(),
      conditions: (fields[4] as List).cast<String>(),
      medications: (fields[5] as List).cast<String>(),
      emergencyContactName: fields[6] as String,
      emergencyContactPhone: fields[7] as String,
      emergencyContactRelation: fields[8] as String,
      isOrganDonor: fields[9] as bool? ?? false,
      pregnancyStatus: fields[10] as String? ?? 'N/A',
      notes: fields[11] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, MedicalProfile obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.bloodGroup)
      ..writeByte(3)
      ..write(obj.allergies)
      ..writeByte(4)
      ..write(obj.conditions)
      ..writeByte(5)
      ..write(obj.medications)
      ..writeByte(6)
      ..write(obj.emergencyContactName)
      ..writeByte(7)
      ..write(obj.emergencyContactPhone)
      ..writeByte(8)
      ..write(obj.emergencyContactRelation)
      ..writeByte(9)
      ..write(obj.isOrganDonor)
      ..writeByte(10)
      ..write(obj.pregnancyStatus)
      ..writeByte(11)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
