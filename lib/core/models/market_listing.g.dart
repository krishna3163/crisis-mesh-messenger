// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'market_listing.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MarketListingAdapter extends TypeAdapter<MarketListing> {
  @override
  final int typeId = 16;

  @override
  MarketListing read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MarketListing(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      listingType: fields[3] as String,
      category: fields[4] as String,
      quantity: fields[5] as double,
      unit: fields[6] as String,
      creatorId: fields[7] as String,
      creatorName: fields[8] as String,
      status: fields[9] as String,
      timestamp: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MarketListing obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.listingType)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.quantity)
      ..writeByte(6)
      ..write(obj.unit)
      ..writeByte(7)
      ..write(obj.creatorId)
      ..writeByte(8)
      ..write(obj.creatorName)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MarketListingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
