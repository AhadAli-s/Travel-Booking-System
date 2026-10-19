import '../core/json_utils.dart';

class TicketReply {
  const TicketReply({
    required this.id,
    required this.senderType,
    required this.message,
    this.createdAt,
  });

  final int id;

  /// "Customer" or "Staff".
  final String senderType;
  final String message;
  final DateTime? createdAt;

  bool get fromStaff => senderType == 'Staff';

  factory TicketReply.fromJson(Map<String, dynamic> json) {
    return TicketReply(
      id: toInt(json['id']),
      senderType: (json['senderType'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      createdAt: parseDate(json['createdAt']),
    );
  }

  static List<TicketReply> listFromJson(dynamic value) {
    if (value is! List) return const <TicketReply>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(TicketReply.fromJson)
        .toList();
  }
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.category,
    required this.subject,
    required this.description,
    required this.status,
    this.bookingId,
    this.createdAt,
    this.updatedAt,
    this.replies = const <TicketReply>[],
  });

  final int id;
  final String category;
  final String subject;
  final String description;
  final String status;
  final int? bookingId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<TicketReply> replies;

  bool get isClosed => status == 'Closed';

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: toInt(json['id']),
      category: (json['category'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      bookingId: json['bookingId'] == null ? null : toInt(json['bookingId']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      replies: TicketReply.listFromJson(json['replies']),
    );
  }

  static List<SupportTicket> listFromJson(dynamic value) {
    if (value is! List) return const <SupportTicket>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(SupportTicket.fromJson)
        .toList();
  }
}
