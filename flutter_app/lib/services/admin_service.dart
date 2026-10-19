import '../core/api_client.dart';
import '../models/admin_dashboard.dart';

class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<AdminDashboardData> fetchDashboard() async {
    final json = await _api.get('/admin/dashboard');
    return AdminDashboardData.fromJson(json as Map<String, dynamic>);
  }
}
