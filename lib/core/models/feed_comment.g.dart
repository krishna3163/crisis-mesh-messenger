// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_comment.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedCommentAdapter extends TypeAdapter<FeedComment> {
  @override
  final int typeId = 8;

  @override
  FeedComment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedComment(
      id: fields[0] as String,
      postId: fields[1] as String,
      authorId: fields[2] as String,
      authorName: fields[3] as String,
      content: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, FeedComment obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.postId)
      ..writeByte(2)
      ..write(obj.authorId)
      ..writeByte(3)
      ..write(obj.authorName)
      ..writeByte(4)
      ..write(obj.content)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedCommentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
