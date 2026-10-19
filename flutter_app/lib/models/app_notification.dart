import '../core/json_utils.dart';

/// Named AppNotification, not Notification, to avoid clashing with Flutter's own
/// widgets.Notification class.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.isRead,
    this.createdAt,
  });

  final int id;
  final String type;
  final String message;
  final bool isRead;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: toInt(json['id']),
      type: (json['type'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      isRead: json['isRead'] == true,
      createdAt: parseDate(json['createdAt']),
    );
  }

  static List<AppNotification> listFromJson(dynamic value) {
    if (value is! List) return const <AppNotification>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(AppNotification.fromJson)
        .toList();
  }
}
