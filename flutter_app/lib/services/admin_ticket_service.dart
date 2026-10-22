import '../core/api_client.dart';
import '../models/ticket.dart';

class AdminTicketService {
  AdminTicketService(this._api);

  final ApiClient _api;

  Future<List<SupportTicket>> list({String? status}) async {
    final json = await _api.get(
      '/tickets',
      query: status == null ? null : {'status': status},
    );
    return SupportTicket.listFromJson(json);
  }

  Future<SupportTicket> getTicket(int id) async {
    final json = await _api.get('/tickets/$id');
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }

  Future<TicketReply> addReply(int ticketId, String message) async {
    final json = await _api.post(
      '/tickets/$ticketId/replies',
      body: {'message': message.trim()},
    );
    return TicketReply.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateStatus(int ticketId, String status) =>
      _api.patch('/tickets/$ticketId/status', body: {'status': status});

  /// Pass null to unassign.
  Future<void> assign(int ticketId, int? staffId) =>
      _api.patch('/tickets/$ticketId/assign', body: {'staffId': staffId});
}
