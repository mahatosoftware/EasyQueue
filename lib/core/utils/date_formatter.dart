import 'package:intl/intl.dart';

class DateFormatter {
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  static String formatDurationMinutes(int minutes) {
    if (minutes < 1) return '< 1 min';
    if (minutes < 60) return '$minutes mins';
    final hours = minutes ~/ 60;
    final remainingMins = minutes % 60;
    if (remainingMins == 0) return '$hours hr${hours > 1 ? 's' : ''}';
    return '$hours hr $remainingMins min';
  }

  static String formatEstimatedWait(int seconds) {
    final minutes = (seconds / 60).round();
    return formatDurationMinutes(minutes);
  }

  /// Safely parses a dynamic value (DateTime, Timestamp, String, or int ms) into DateTime
  static DateTime parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    try {
      final dynamic dyn = value;
      if (dyn.toDate is Function) {
        return dyn.toDate() as DateTime;
      }
    } catch (_) {}
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  /// Safely parses a nullable dynamic value into DateTime?
  static DateTime? parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    return parseDateTime(value);
  }
}

