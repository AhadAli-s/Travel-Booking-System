import 'package:intl/intl.dart';

/// 1450 -> "£1,450", 1450.5 -> "£1,450.50"
String formatMoney(double amount) {
  final hasPence = (amount * 100).round() % 100 != 0;
  return NumberFormat.currency(
    symbol: '£',
    decimalDigits: hasPence ? 2 : 0,
  ).format(amount);
}

/// "15 Oct 2026"
String formatDate(DateTime? date) {
  if (date == null) return '-';
  return DateFormat('d MMM yyyy').format(date);
}

/// "12-19 Oct", "28 Oct - 4 Nov" or "28 Dec 2026 - 4 Jan 2027"
String formatDateRange(DateTime? start, DateTime? end) {
  if (start == null) return '-';
  if (end == null) return formatDate(start);
  if (start.year == end.year && start.month == end.month) {
    return '${start.day}-${end.day} ${DateFormat('MMM').format(end)}';
  }
  if (start.year == end.year) {
    return '${DateFormat('d MMM').format(start)} - ${DateFormat('d MMM').format(end)}';
  }
  return '${formatDate(start)} - ${formatDate(end)}';
}

/// Flight and transfer times are entered by the agency as local airport time and
/// stored as UTC, so they are shown exactly as stored: "Wed 4 Nov, 06:00".
String formatDateTimeUtc(DateTime? value) {
  if (value == null) return '-';
  return DateFormat('EEE d MMM, HH:mm').format(value.toUtc());
}

/// "AwaitingPayment" -> "Awaiting Payment"
String statusLabel(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  return raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
}

/// "BookingConfirmation" -> "Booking Confirmation", "ATOLCertificate" -> "ATOL Certificate"
String documentTypeLabel(String type) {
  if (type == 'ATOLCertificate') return 'ATOL Certificate';
  return statusLabel(type);
}

/// "2 adults, 1 child"
String travellersLabel(int adults, int children, int infants) {
  final parts = <String>[];
  if (adults > 0) parts.add('$adults ${adults == 1 ? 'adult' : 'adults'}');
  if (children > 0)
    parts.add('$children ${children == 1 ? 'child' : 'children'}');
  if (infants > 0) parts.add('$infants ${infants == 1 ? 'infant' : 'infants'}');
  return parts.isEmpty ? '-' : parts.join(', ');
}

/// Hides all but the last [visible] characters: "AB1234567" -> "•••••4567"
String maskSecret(String? value, {int visible = 4}) {
  if (value == null || value.isEmpty) return '-';
  if (value.length <= visible) return '•' * value.length;
  return '•' * (value.length - visible) +
      value.substring(value.length - visible);
}
