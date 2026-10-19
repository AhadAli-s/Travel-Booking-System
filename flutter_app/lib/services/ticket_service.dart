import '../core/api_client.dart';
import '../models/ticket.dart';

class TicketService {
  TicketService(this._api);

  final ApiClient _api;

  Future<List<SupportTicket>> myTickets() async {
    final json = await _api.get('/tickets/my');
    return SupportTicket.listFromJson(json);
  }

  Future<SupportTicket> getTicket(int id) async {
    final json = await _api.get('/tickets/$id');
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }

  Future<SupportTicket> createTicket({
    required String category,
    required String subject,
    required String description,
    int? bookingId,
  }) async {
    final body = <String, dynamic>{
      'category': category,
      'subject': subject.trim(),
      'description': description.trim(),
    };
    if (bookingId != null) body['bookingId'] = bookingId;
    final json = await _api.post('/tickets', body: body);
    return SupportTicket.fromJson(json as Map<String, dynamic>);
  }

  Future<TicketReply> addReply(int ticketId, String message) async {
    final json = await _api.post(
      '/tickets/$ticketId/replies',
      body: {'message': message.trim()},
    );
    return TicketReply.fromJson(json as Map<String, dynamic>);
  }
}
