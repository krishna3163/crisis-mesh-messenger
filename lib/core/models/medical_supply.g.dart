// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medical_supply.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MedicalSupplyAdapter extends TypeAdapter<MedicalSupply> {
  @override
  final int typeId = 13;

  @override
  MedicalSupply read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MedicalSupply(
      id: fields[0] as String,
      name: fields[1] as String,
      category: fields[2] as String,
      quantity: fields[3] as double,
      unit: fields[4] as String,
      lowStockThreshold: fields[5] as double,
      timestamp: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MedicalSupply obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.lowStockThreshold)
      ..writeByte(6)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalSupplyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
