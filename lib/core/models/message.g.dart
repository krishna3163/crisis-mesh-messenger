// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MessageAdapter extends TypeAdapter<Message> {
  @override
  final int typeId = 0;

  @override
  Message read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Message(
      id: fields[0] as String,
      senderId: fields[1] as String,
      recipientId: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
      status: fields[5] as MessageStatus,
      hopCount: fields[6] as int,
      maxHops: fields[7] as int,
      routePath: (fields[8] as List).cast<String>(),
      encryptedContent: fields[9] as String?,
      isEncrypted: fields[10] as bool,
      groupId: fields[11] as String?,
      replyToId: fields[12] as String?,
      replyToContent: fields[13] as String?,
      replyToSenderName: fields[14] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Message obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.senderId)
      ..writeByte(2)
      ..write(obj.recipientId)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.hopCount)
      ..writeByte(7)
      ..write(obj.maxHops)
      ..writeByte(8)
      ..write(obj.routePath)
      ..writeByte(9)
      ..write(obj.encryptedContent)
      ..writeByte(10)
      ..write(obj.isEncrypted)
      ..writeByte(11)
      ..write(obj.groupId)
      ..writeByte(12)
      ..write(obj.replyToId)
      ..writeByte(13)
      ..write(obj.replyToContent)
      ..writeByte(14)
      ..write(obj.replyToSenderName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MessageStatusAdapter extends TypeAdapter<MessageStatus> {
  @override
  final int typeId = 3;

  @override
  MessageStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MessageStatus.sending;
      case 1:
        return MessageStatus.sent;
      case 2:
        return MessageStatus.delivered;
      case 3:
        return MessageStatus.failed;
      case 4:
        return MessageStatus.relayed;
      case 5:
        return MessageStatus.read;
      default:
        return MessageStatus.sending;
    }
  }

  @override
  void write(BinaryWriter writer, MessageStatus obj) {
    switch (obj) {
      case MessageStatus.sending:
        writer.writeByte(0);
        break;
      case MessageStatus.sent:
        writer.writeByte(1);
        break;
      case MessageStatus.delivered:
        writer.writeByte(2);
        break;
      case MessageStatus.failed:
        writer.writeByte(3);
        break;
      case MessageStatus.relayed:
        writer.writeByte(4);
        break;
      case MessageStatus.read:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
