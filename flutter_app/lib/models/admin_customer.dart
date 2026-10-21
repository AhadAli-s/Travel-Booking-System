import '../core/json_utils.dart';
import 'booking.dart';
import 'contact_note.dart';
import 'ticket.dart';

/// One row in the staff customer list (GET /admin/customers).
class CustomerSummary {
  const CustomerSummary({
    required this.id,
    required this.fullName,
    required this.email,
    required this.totalBookings,
    required this.activeBookings,
    this.phone,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phone;
  final DateTime? createdAt;
  final int totalBookings;
  final int activeBookings;

  factory CustomerSummary.fromJson(Map<String, dynamic> json) {
    return CustomerSummary(
      id: toInt(json['id']),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: toNullableString(json['phone']),
      createdAt: parseDate(json['createdAt']),
      totalBookings: toInt(json['totalBookings']),
      activeBookings: toInt(json['activeBookings']),
    );
  }
}

/// GET /admin/customers/:id — the customer plus everything staff need to help them.
class AdminCustomerDetail {
  const AdminCustomerDetail({
    required this.customer,
    required this.bookings,
    required this.tickets,
    required this.contactHistory,
  });

  final CustomerSummary customer;
  final List<Booking> bookings;
  final List<SupportTicket> tickets;
  final List<ContactNote> contactHistory;

  factory AdminCustomerDetail.fromJson(Map<String, dynamic> json) {
    return AdminCustomerDetail(
      customer: CustomerSummary.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      bookings: Booking.listFromJson(json['bookings']),
      tickets: SupportTicket.listFromJson(json['tickets']),
      contactHistory: ContactNote.listFromJson(json['contactHistory']),
    );
  }
}
