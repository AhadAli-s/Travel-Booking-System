import 'package:flutter/material.dart';

import 'format.dart';

/// Booking statuses, document types and staff roles, matching the enums in
/// backend/src/controllers exactly (bookingController.js VALID_STATUSES,
/// documentController.js VALID_DOCUMENT_TYPES, staffController.js ROLES).

const List<String> bookingStatuses = <String>[
  'Pending',
  'Processing',
  'AwaitingPayment',
  'PaymentReceived',
  'Confirmed',
  'DocumentsPending',
  'DocumentsIssued',
  'ReadyToTravel',
  'TravelCompleted',
  'Cancelled',
  'Closed',
];

const List<String> documentTypes = <String>[
  'BookingConfirmation',
  'FlightTickets',
  'HotelVoucher',
  'TransferVoucher',
  'TravelInsurance',
  'VisaDocuments',
  'ATOLCertificate',
  'Invoice',
  'PaymentReceipt',
];

const List<String> staffRoles = <String>[
  'Administrator',
  'BookingAgent',
  'AccountsStaff',
  'SupportAgent',
];

String staffRoleLabel(String role) => statusLabel(role);

/// Which staff roles can perform each kind of admin action, mirroring the
/// route guards in backend/src/routes exactly. The UI hides actions the
/// signed in staff member cannot perform; the server enforces it regardless.
bool roleCanEditBookings(String role) =>
    role == 'Administrator' || role == 'BookingAgent';

bool roleCanManagePayments(String role) =>
    role == 'Administrator' || role == 'AccountsStaff';

bool roleCanManageDocuments(String role) =>
    role == 'Administrator' ||
    role == 'BookingAgent' ||
    role == 'AccountsStaff';

bool roleCanManageTickets(String role) =>
    role == 'Administrator' || role == 'SupportAgent';

bool roleCanManageStaff(String role) => role == 'Administrator';

IconData documentTypeIcon(String type) {
  switch (type) {
    case 'BookingConfirmation':
      return Icons.confirmation_number_outlined;
    case 'FlightTickets':
      return Icons.flight;
    case 'HotelVoucher':
      return Icons.hotel_outlined;
    case 'TransferVoucher':
      return Icons.airport_shuttle_outlined;
    case 'TravelInsurance':
      return Icons.health_and_safety_outlined;
    case 'VisaDocuments':
      return Icons.badge_outlined;
    case 'ATOLCertificate':
      return Icons.verified_user_outlined;
    case 'Invoice':
      return Icons.receipt_long_outlined;
    case 'PaymentReceipt':
      return Icons.receipt_outlined;
    default:
      return Icons.description_outlined;
  }
}
