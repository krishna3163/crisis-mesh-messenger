// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rescue_task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RescueTaskAdapter extends TypeAdapter<RescueTask> {
  @override
  final int typeId = 12;

  @override
  RescueTask read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RescueTask(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      priority: fields[3] as String,
      latitude: fields[4] as double?,
      longitude: fields[5] as double?,
      assignedTeamId: fields[6] as String?,
      status: fields[7] as String,
      timestamp: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, RescueTask obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.priority)
      ..writeByte(4)
      ..write(obj.latitude)
      ..writeByte(5)
      ..write(obj.longitude)
      ..writeByte(6)
      ..write(obj.assignedTeamId)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RescueTaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
