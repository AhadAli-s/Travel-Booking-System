import '../core/api_client.dart';
import '../models/staff.dart';

/// Administrator only. The server enforces this; the UI also hides these
/// screens from non-administrators (see admin_meta.dart roleCanManageStaff).
class AdminStaffService {
  AdminStaffService(this._api);

  final ApiClient _api;

  Future<List<Staff>> list() async {
    final json = await _api.get('/admin/staff');
    return Staff.listFromJson(json);
  }

  Future<Staff> create({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final json = await _api.post(
      '/admin/staff',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      },
    );
    return Staff.fromJson(json as Map<String, dynamic>);
  }

  Future<Staff> update(
    int id, {
    String? fullName,
    String? role,
    String? status,
    String? password,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (role != null) body['role'] = role;
    if (status != null) body['status'] = status;
    if (password != null) body['password'] = password;
    final json = await _api.patch('/admin/staff/$id', body: body);
    return Staff.fromJson(json as Map<String, dynamic>);
  }
}
