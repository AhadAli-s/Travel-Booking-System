import '../core/api_client.dart';
import '../core/json_utils.dart';
import '../models/admin_customer.dart';
import '../models/contact_note.dart';

class AdminCustomerService {
  AdminCustomerService(this._api);

  final ApiClient _api;

  /// Returns (total, customers). The server paginates with limit/offset.
  Future<(int, List<CustomerSummary>)> list({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final query = <String, String>{'limit': '$limit', 'offset': '$offset'};
    if (search != null && search.trim().isNotEmpty)
      query['search'] = search.trim();
    final json = await _api.get(
      '/admin/customers',
      query: query,
    ) as Map<String, dynamic>;
    final customers =
        (json['customers'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(CustomerSummary.fromJson)
            .toList() ??
        const <CustomerSummary>[];
    return (toInt(json['total']), customers);
  }

  Future<AdminCustomerDetail> detail(int customerId) async {
    final json = await _api.get('/admin/customers/$customerId');
    return AdminCustomerDetail.fromJson(json as Map<String, dynamic>);
  }

  Future<ContactNote> addNote(
    int customerId, {
    required String note,
    String channel = 'Phone',
    int? bookingId,
  }) async {
    final json = await _api.post(
      '/admin/customers/$customerId/notes',
      body: {
        'note': note,
        'channel': channel,
        if (bookingId != null) 'bookingId': bookingId,
      },
    );
    return ContactNote.fromJson(json as Map<String, dynamic>);
  }
}
