import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'leader_vote.g.dart';

@HiveType(typeId: 17)
class LeaderVote extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String nomineeId;

  @HiveField(2)
  final String nomineeName;

  @HiveField(3)
  final String voterId;

  @HiveField(4)
  final String voterName;

  @HiveField(5)
  final DateTime timestamp;

  const LeaderVote({
    required this.id,
    required this.nomineeId,
    required this.nomineeName,
    required this.voterId,
    required this.voterName,
    required this.timestamp,
  });

  LeaderVote copyWith({
    String? id,
    String? nomineeId,
    String? nomineeName,
    String? voterId,
    String? voterName,
    DateTime? timestamp,
  }) {
    return LeaderVote(
      id: id ?? this.id,
      nomineeId: nomineeId ?? this.nomineeId,
      nomineeName: nomineeName ?? this.nomineeName,
      voterId: voterId ?? this.voterId,
      voterName: voterName ?? this.voterName,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomineeId': nomineeId,
        'nomineeName': nomineeName,
        'voterId': voterId,
        'voterName': voterName,
        'timestamp': timestamp.toIso8601String(),
      };

  factory LeaderVote.fromJson(Map<String, dynamic> json) => LeaderVote(
        id: json['id'] as String,
        nomineeId: json['nomineeId'] as String,
        nomineeName: json['nomineeName'] as String,
        voterId: json['voterId'] as String,
        voterName: json['voterName'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  @override
  List<Object?> get props => [
        id,
        nomineeId,
        nomineeName,
        voterId,
        voterName,
        timestamp,
      ];
}
