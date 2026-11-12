import '../../core/utils/date_formatter.dart';

class NotificationPreferences {
  final bool pushEnabled;
  final bool smsEnabled;
  final bool whatsappEnabled;
  final bool soundAlerts;
  final bool vibrateOnCall;
  final String? quietHoursStart;
  final String? quietHoursEnd;

  const NotificationPreferences({
    this.pushEnabled = true,
    this.smsEnabled = true,
    this.whatsappEnabled = false,
    this.soundAlerts = true,
    this.vibrateOnCall = true,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    return NotificationPreferences(
      pushEnabled: map['pushEnabled'] ?? true,
      smsEnabled: map['smsEnabled'] ?? true,
      whatsappEnabled: map['whatsappEnabled'] ?? false,
      soundAlerts: map['soundAlerts'] ?? true,
      vibrateOnCall: map['vibrateOnCall'] ?? true,
      quietHoursStart: map['quietHoursStart'],
      quietHoursEnd: map['quietHoursEnd'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pushEnabled': pushEnabled,
      'smsEnabled': smsEnabled,
      'whatsappEnabled': whatsappEnabled,
      'soundAlerts': soundAlerts,
      'vibrateOnCall': vibrateOnCall,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? smsEnabled,
    bool? whatsappEnabled,
    bool? soundAlerts,
    bool? vibrateOnCall,
    String? quietHoursStart,
    String? quietHoursEnd,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
      soundAlerts: soundAlerts ?? this.soundAlerts,
      vibrateOnCall: vibrateOnCall ?? this.vibrateOnCall,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
    );
  }
}

class UserModel {
  final String id;
  final String displayName;
  final String? email;
  final String phoneNumber;
  final String countryCode;
  final String? photoUrl;
  final String preferredLanguage;
  final NotificationPreferences notificationPreferences;
  final bool isGuest;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.displayName,
    this.email,
    required this.phoneNumber,
    this.countryCode = '+1',
    this.photoUrl,
    this.preferredLanguage = 'en',
    this.notificationPreferences = const NotificationPreferences(),
    this.isGuest = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      displayName: map['displayName'] ?? map['name'] ?? 'Customer',
      email: map['email'],
      phoneNumber: map['phoneNumber'] ?? '',
      countryCode: map['countryCode'] ?? '+1',
      photoUrl: map['photoUrl'] ?? map['avatarUrl'],
      preferredLanguage: map['preferredLanguage'] ?? 'en',
      notificationPreferences: map['notificationPreferences'] != null
          ? NotificationPreferences.fromMap(
              map['notificationPreferences'] is Map<String, dynamic>
                  ? map['notificationPreferences'] as Map<String, dynamic>
                  : Map<String, dynamic>.from(map['notificationPreferences'] as Map),
            )
          : const NotificationPreferences(),
      isGuest: map['isGuest'] ?? false,
      createdAt: DateFormatter.parseDateTime(map['createdAt']),
      updatedAt: DateFormatter.parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'photoUrl': photoUrl,
      'preferredLanguage': preferredLanguage,
      'notificationPreferences': notificationPreferences.toMap(),
      'isGuest': isGuest,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? email,
    String? phoneNumber,
    String? countryCode,
    String? photoUrl,
    String? preferredLanguage,
    NotificationPreferences? notificationPreferences,
    bool? isGuest,
  }) {
    return UserModel(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      photoUrl: photoUrl ?? this.photoUrl,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      notificationPreferences:
          notificationPreferences ?? this.notificationPreferences,
      isGuest: isGuest ?? this.isGuest,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
