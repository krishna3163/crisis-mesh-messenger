// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'triage_card.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TriageCardAdapter extends TypeAdapter<TriageCard> {
  @override
  final int typeId = 11;

  @override
  TriageCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TriageCard(
      id: fields[0] as String,
      patientName: fields[1] as String,
      status: fields[2] as String,
      injuries: (fields[3] as List).cast<String>(),
      heartRate: fields[4] as int,
      bloodPressure: fields[5] as String,
      temperature: fields[6] as double,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      assignedTeamId: fields[9] as String?,
      isResolved: fields[10] as bool? ?? false,
      timestamp: fields[11] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TriageCard obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.patientName)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.injuries)
      ..writeByte(4)
      ..write(obj.heartRate)
      ..writeByte(5)
      ..write(obj.bloodPressure)
      ..writeByte(6)
      ..write(obj.temperature)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.assignedTeamId)
      ..writeByte(10)
      ..write(obj.isResolved)
      ..writeByte(11)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
