import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/dashboard.dart';

class DashboardService {
  DashboardService(this._api);

  final ApiClient _api;

  Future<DashboardData> fetchDashboard() async {
    final json = await _api.get('/dashboard');
    return DashboardData.fromJson(json as Map<String, dynamic>);
  }

  Future<int> unreadNotificationCount() async {
    final json = await _api.get('/notifications/unread-count');
    if (json is Map<String, dynamic>) return toInt(json['unreadCount']);
    return 0;
  }
}
