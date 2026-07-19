// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leader_vote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LeaderVoteAdapter extends TypeAdapter<LeaderVote> {
  @override
  final int typeId = 17;

  @override
  LeaderVote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LeaderVote(
      id: fields[0] as String,
      nomineeId: fields[1] as String,
      nomineeName: fields[2] as String,
      voterId: fields[3] as String,
      voterName: fields[4] as String,
      timestamp: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LeaderVote obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nomineeId)
      ..writeByte(2)
      ..write(obj.nomineeName)
      ..writeByte(3)
      ..write(obj.voterId)
      ..writeByte(4)
      ..write(obj.voterName)
      ..writeByte(5)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderVoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
