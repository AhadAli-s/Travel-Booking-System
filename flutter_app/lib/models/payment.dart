import '../core/json_utils.dart';

/// Totals for a booking. Comes from the dashboard, the booking itself or the payments endpoint.
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
    final total = toDouble(json['totalPackagePrice']);
    final paid = toDouble(json['amountPaid']);
    // Booking objects do not carry remainingBalance, so work it out when missing.
    final remaining = json.containsKey('remainingBalance')
        ? toDouble(json['remainingBalance'])
        : (total - paid < 0 ? 0.0 : total - paid);
    return PaymentSummary(
      totalPackagePrice: total,
      amountPaid: paid,
      remainingBalance: remaining,
      paymentDueDate: parseDate(json['paymentDueDate']),
      paymentStatus: (json['paymentStatus'] ?? '').toString(),
    );
  }

  /// True when money is still owed and the due date is before today.
  bool get isOverdue {
    final due = paymentDueDate;
    if (due == null || remainingBalance <= 0) return false;
    final now = DateTime.now();
    return DateTime(due.year, due.month, due.day).isBefore(DateTime(now.year, now.month, now.day));
  }
}

/// One line in the payment history. Refunds have a negative [amount].
class PaymentEntry {
  const PaymentEntry({
    required this.id,
    required this.amount,
    this.paymentDate,
    this.method,
    this.note,
  });

  final int id;
  final double amount;
  final DateTime? paymentDate;
  final String? method;
  final String? note;

  bool get isRefund => amount < 0;

  factory PaymentEntry.fromJson(Map<String, dynamic> json) {
    return PaymentEntry(
      id: toInt(json['id']),
      amount: toDouble(json['amount']),
      paymentDate: parseDate(json['paymentDate']),
      method: toNullableString(json['method']),
      note: toNullableString(json['note']),
    );
  }
}

class PaymentDetails {
  const PaymentDetails({required this.summary, required this.history});

  final PaymentSummary summary;
  final List<PaymentEntry> history;

  factory PaymentDetails.fromJson(Map<String, dynamic> json) {
    final history = json['history'];
    return PaymentDetails(
      summary: PaymentSummary.fromJson(json),
      history: history is List
          ? history.whereType<Map<String, dynamic>>().map(PaymentEntry.fromJson).toList()
          : const <PaymentEntry>[],
    );
  }
}

class Receipt {
  const Receipt({
    required this.receiptNumber,
    required this.bookingReference,
    required this.destination,
    required this.amount,
    required this.totalPackagePrice,
    required this.amountPaidToDate,
    required this.remainingBalance,
    this.method,
    this.paymentDate,
    this.note,
  });

  final String receiptNumber;
  final String bookingReference;
  final String destination;
  final double amount;
  final String? method;
  final DateTime? paymentDate;
  final String? note;
  final double totalPackagePrice;
  final double amountPaidToDate;
  final double remainingBalance;

  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      receiptNumber: (json['receiptNumber'] ?? '').toString(),
      bookingReference: (json['bookingReference'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      amount: toDouble(json['amount']),
      method: toNullableString(json['method']),
      paymentDate: parseDate(json['paymentDate']),
      note: toNullableString(json['note']),
      totalPackagePrice: toDouble(json['totalPackagePrice']),
      amountPaidToDate: toDouble(json['amountPaidToDate']),
      remainingBalance: toDouble(json['remainingBalance']),
    );
  }
}