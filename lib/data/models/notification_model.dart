import '../../core/utils/date_formatter.dart';

class AppNotificationModel {
  final String id;
  final String title;
  final String message;
  final String type; // token_confirmed, approaching_turn, called, delay, cancelled
  final String? entryId;
  final String? businessId;
  final DateTime? readAt;
  final DateTime createdAt;

  AppNotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.entryId,
    this.businessId,
    this.readAt,
    required this.createdAt,
  });

  bool get isRead => readAt != null;

  factory AppNotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return AppNotificationModel(
      id: id,
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      entryId: map['entryId'],
      businessId: map['businessId'],
      readAt: DateFormatter.parseNullableDateTime(map['readAt']),
      createdAt: DateFormatter.parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'entryId': entryId,
      'businessId': businessId,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
