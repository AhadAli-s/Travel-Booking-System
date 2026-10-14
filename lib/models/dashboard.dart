import '../core/json_utils.dart';

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

class PaymentSummary {
  const PaymentSummary({
    required this.totalPackagePrice,
    required this.amountPaid,
    required this.remainingBalance,
    required this.paymentStatus,
    this.paymentDueDate,
  });

  final double totalPackagePrice;
  final double amountPaid;
  final double remainingBalance;
  final DateTime? paymentDueDate;
  final String paymentStatus;

  factory PaymentSummary.fromJson(Map<String, dynamic> json) {
    return PaymentSummary(
      totalPackagePrice: toDouble(json['totalPackagePrice']),
      amountPaid: toDouble(json['amountPaid']),
      remainingBalance: toDouble(json['remainingBalance']),
      paymentDueDate: parseDate(json['paymentDueDate']),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
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
