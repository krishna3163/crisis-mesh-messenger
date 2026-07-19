// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChannelMessageAdapter extends TypeAdapter<ChannelMessage> {
  @override
  final int typeId = 7;

  @override
  ChannelMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChannelMessage(
      id: fields[0] as String,
      channelId: fields[1] as String,
      senderId: fields[2] as String,
      senderName: fields[3] as String,
      content: fields[4] as String,
      timestamp: fields[5] as DateTime,
      hopCount: fields[6] as int,
      routePath: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ChannelMessage obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.channelId)
      ..writeByte(2)
      ..write(obj.senderId)
      ..writeByte(3)
      ..write(obj.senderName)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.hopCount)
      ..writeByte(7)
      ..write(obj.routePath);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
