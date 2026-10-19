import '../core/json_utils.dart';

class AdminDashboardData {
  const AdminDashboardData({
    required this.totalBookings,
    required this.pendingBookings,
    required this.confirmedBookings,
    required this.cancelledBookings,
    required this.travellingSoon,
    required this.outstandingPayments,
    required this.openSupportTickets,
  });

  final int totalBookings;
  final int pendingBookings;
  final int confirmedBookings;
  final int cancelledBookings;
  final int travellingSoon;
  final int outstandingPayments;
  final int openSupportTickets;

  factory AdminDashboardData.fromJson(Map<String, dynamic> json) {
    return AdminDashboardData(
      totalBookings: toInt(json['totalBookings']),
      pendingBookings: toInt(json['pendingBookings']),
      confirmedBookings: toInt(json['confirmedBookings']),
      cancelledBookings: toInt(json['cancelledBookings']),
      travellingSoon: toInt(json['travellingSoon']),
      outstandingPayments: toInt(json['outstandingPayments']),
      openSupportTickets: toInt(json['openSupportTickets']),
    );
  }
}
