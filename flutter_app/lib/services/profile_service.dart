import '../core/api_client.dart';
import '../models/customer.dart';

class ProfileService {
  ProfileService(this._api);

  final ApiClient _api;

  Future<Customer> update({String? fullName, String? phone}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName.trim();
    if (phone != null)
      body['phone'] = phone.trim().isEmpty ? null : phone.trim();
    final json = await _api.patch('/profile', body: body);
    return Customer.fromJson(json as Map<String, dynamic>);
  }
}
