// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_post.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FeedPostAdapter extends TypeAdapter<FeedPost> {
  @override
  final int typeId = 5;

  @override
  FeedPost read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FeedPost(
      id: fields[0] as String,
      authorId: fields[1] as String,
      authorName: fields[2] as String,
      content: fields[3] as String,
      timestamp: fields[4] as DateTime,
      routePath: (fields[5] as List).cast<String>(),
      hopCount: fields[6] as int,
      likedBy: fields[7] != null ? (fields[7] as List).cast<String>() : const [],
    );
  }

  @override
  void write(BinaryWriter writer, FeedPost obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.authorId)
      ..writeByte(2)
      ..write(obj.authorName)
      ..writeByte(3)
      ..write(obj.content)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.routePath)
      ..writeByte(6)
      ..write(obj.hopCount)
      ..writeByte(7)
      ..write(obj.likedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeedPostAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
