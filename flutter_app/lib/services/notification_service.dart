import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/app_notification.dart';

class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> list() async {
    final json = await _api.get('/notifications');
    return AppNotification.listFromJson(json);
  }

  Future<int> unreadCount() async {
    final json = await _api.get('/notifications/unread-count');
    if (json is Map<String, dynamic>) return toInt(json['unreadCount']);
    return 0;
  }

  Future<void> markRead(int id) => _api.patch('/notifications/$id/read');

  Future<void> markAllRead() => _api.patch('/notifications/read-all');
}
