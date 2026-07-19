// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_email.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineEmailAdapter extends TypeAdapter<OfflineEmail> {
  @override
  final int typeId = 15;

  @override
  OfflineEmail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineEmail(
      id: fields[0] as String,
      senderEmail: fields[1] as String,
      recipientEmail: fields[2] as String,
      subject: fields[3] as String,
      body: fields[4] as String,
      status: fields[5] as String,
      timestamp: fields[6] as DateTime,
      hopCount: fields[7] as int? ?? 0,
      routePath: (fields[8] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, OfflineEmail obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderEmail)
      ..writeByte(2)
      ..write(obj.recipientEmail)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.body)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.timestamp)
      ..writeByte(7)
      ..write(obj.hopCount)
      ..writeByte(8)
      ..write(obj.routePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineEmailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
