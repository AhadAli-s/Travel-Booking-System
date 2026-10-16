import '../core/json_utils.dart';
import 'payment.dart';

class UpcomingTrip {
  const UpcomingTrip({
    required this.bookingId,
    required this.bookingReference,
    required this.destination,
    required this.status,
    required this.daysUntilTravel,
    this.departureCity,
    this.travelDate,
    this.returnDate,
  });

  final int bookingId;
  final String bookingReference;
  final String destination;
  final String? departureCity;
  final DateTime? travelDate;
  final DateTime? returnDate;
  final String status;
  final int daysUntilTravel;

  factory UpcomingTrip.fromJson(Map<String, dynamic> json) {
    return UpcomingTrip(
      bookingId: toInt(json['bookingId']),
      bookingReference: (json['bookingReference'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      departureCity: toNullableString(json['departureCity']),
      travelDate: parseDate(json['travelDate']),
      returnDate: parseDate(json['returnDate']),
      status: (json['status'] ?? '').toString(),
      daysUntilTravel: toInt(json['daysUntilTravel']),
    );
  }
}

class DashboardData {
  const DashboardData({
    required this.documentsAvailable,
    required this.activeTickets,
    this.trip,
    this.payment,
  });

  final UpcomingTrip? trip;
  final PaymentSummary? payment;
  final int documentsAvailable;
  final int activeTickets;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final trip = json['upcomingTrip'];
    final payment = json['payment'];
    final documents = json['documents'];
    final support = json['support'];
    return DashboardData(
      trip: trip is Map<String, dynamic> ? UpcomingTrip.fromJson(trip) : null,
      payment: payment is Map<String, dynamic>
          ? PaymentSummary.fromJson(payment)
          : null,
      documentsAvailable: documents is Map<String, dynamic>
          ? toInt(documents['available'])
          : 0,
      activeTickets: support is Map<String, dynamic>
          ? toInt(support['activeTickets'])
          : 0,
    );
  }
}
