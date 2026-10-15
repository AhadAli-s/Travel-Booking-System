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

/// "AwaitingPayment" -> "Awaiting Payment"
String statusLabel(String? raw) {
  if (raw == null || raw.isEmpty) return '-';
  return raw.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]}',
  );
}
