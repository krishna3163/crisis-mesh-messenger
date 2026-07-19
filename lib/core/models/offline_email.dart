import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'offline_email.g.dart';

@HiveType(typeId: 15)
class OfflineEmail extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String senderEmail;

  @HiveField(2)
  final String recipientEmail;

  @HiveField(3)
  final String subject;

  @HiveField(4)
  final String body;

  @HiveField(5)
  final String status; // 'DRAFT', 'QUEUED', 'RELAYED', 'SENT'

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  final int hopCount;

  @HiveField(8)
  final List<String> routePath;

  const OfflineEmail({
    required this.id,
    required this.senderEmail,
    required this.recipientEmail,
    required this.subject,
    required this.body,
    required this.status,
    required this.timestamp,
    this.hopCount = 0,
    this.routePath = const [],
  });

  OfflineEmail copyWith({
    String? id,
    String? senderEmail,
    String? recipientEmail,
    String? subject,
    String? body,
    String? status,
    DateTime? timestamp,
    int? hopCount,
    List<String>? routePath,
  }) {
    return OfflineEmail(
      id: id ?? this.id,
      senderEmail: senderEmail ?? this.senderEmail,
      recipientEmail: recipientEmail ?? this.recipientEmail,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      hopCount: hopCount ?? this.hopCount,
      routePath: routePath ?? this.routePath,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'senderEmail': senderEmail,
        'recipientEmail': recipientEmail,
        'subject': subject,
        'body': body,
        'status': status,
        'timestamp': timestamp.toIso8601String(),
        'hopCount': hopCount,
        'routePath': routePath,
      };

  factory OfflineEmail.fromJson(Map<String, dynamic> json) => OfflineEmail(
        id: json['id'] as String,
        senderEmail: json['senderEmail'] as String,
        recipientEmail: json['recipientEmail'] as String,
        subject: json['subject'] as String,
        body: json['body'] as String,
        status: json['status'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        hopCount: json['hopCount'] as int? ?? 0,
        routePath: (json['routePath'] as List).cast<String>(),
      );

  @override
  List<Object?> get props => [
        id,
        senderEmail,
        recipientEmail,
        subject,
        body,
        status,
        timestamp,
        hopCount,
        routePath,
      ];
}
