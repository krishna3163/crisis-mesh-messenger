// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landing_zone.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LandingZoneAdapter extends TypeAdapter<LandingZone> {
  @override
  final int typeId = 14;

  @override
  LandingZone read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LandingZone(
      id: fields[0] as String,
      name: fields[1] as String,
      latitude: fields[2] as double,
      longitude: fields[3] as double,
      slope: fields[4] as double,
      surfaceType: fields[5] as String,
      sizeMeters: fields[6] as double,
      score: fields[7] as double,
      isMarked: fields[8] as bool? ?? false,
      timestamp: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LandingZone obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.latitude)
      ..writeByte(3)
      ..write(obj.longitude)
      ..writeByte(4)
      ..write(obj.slope)
      ..writeByte(5)
      ..write(obj.surfaceType)
      ..writeByte(6)
      ..write(obj.sizeMeters)
      ..writeByte(7)
      ..write(obj.score)
      ..writeByte(8)
      ..write(obj.isMarked)
      ..writeByte(9)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LandingZoneAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
