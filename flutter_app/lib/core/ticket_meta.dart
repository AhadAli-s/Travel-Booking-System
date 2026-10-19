import 'package:flutter/material.dart';

/// Category and status choices and labels for support tickets, matching the
/// enums in backend/src/controllers/ticketController.js exactly.
const List<String> ticketCategories = <String>[
  'Flight',
  'Hotel',
  'Payment',
  'Transfer',
  'Document',
  'PassengerDetails',
  'CancellationRequest',
  'GeneralSupport',
];

const List<String> ticketStatuses = <String>[
  'Open',
  'InProgress',
  'WaitingForCustomer',
  'Resolved',
  'Closed',
];

String ticketCategoryLabel(String category) {
  switch (category) {
    case 'PassengerDetails':
      return 'Passenger Details';
    case 'CancellationRequest':
      return 'Cancellation Request';
    case 'GeneralSupport':
      return 'General Support';
    default:
      return category.replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      );
  }
}

IconData ticketCategoryIcon(String category) {
  switch (category) {
    case 'Flight':
      return Icons.flight_outlined;
    case 'Hotel':
      return Icons.hotel_outlined;
    case 'Payment':
      return Icons.account_balance_wallet_outlined;
    case 'Transfer':
      return Icons.airport_shuttle_outlined;
    case 'Document':
      return Icons.description_outlined;
    case 'PassengerDetails':
      return Icons.people_outline;
    case 'CancellationRequest':
      return Icons.cancel_outlined;
    default:
      return Icons.help_outline;
  }
}
