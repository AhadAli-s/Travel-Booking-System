import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../models/payment.dart';
import '../services/admin_booking_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Record a deposit or payment against a booking. Returns true if recorded.
/// [remainingBalance] is shown as a hint; the server still enforces the cap.
Future<bool?> showRecordPaymentDialog(
  BuildContext context,
  AdminBookingService service,
  int bookingId,
  PaymentSummary? summary,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _PaymentDialog(
      service: service,
      bookingId: bookingId,
      summary: summary,
      isRefund: false,
    ),
  );
}

/// Issue a refund against a booking. Returns true if issued.
Future<bool?> showIssueRefundDialog(
  BuildContext context,
  AdminBookingService service,
  int bookingId,
  PaymentSummary? summary,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _PaymentDialog(
      service: service,
      bookingId: bookingId,
      summary: summary,
      isRefund: true,
    ),
  );
}

class _PaymentDialog extends StatefulWidget {
  const _PaymentDialog({
    required this.service,
    required this.bookingId,
    required this.summary,
    required this.isRefund,
  });

  final AdminBookingService service;
  final int bookingId;
  final PaymentSummary? summary;
  final bool isRefund;

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _method = 'Card';
  bool _loading = false;
  String? _error;

  static const _methods = ['Card', 'Bank Transfer', 'Cash', 'Cheque'];

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount greater than 0');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.isRefund) {
        await widget.service.issueRefund(
          widget.bookingId,
          amount: amount,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      } else {
        await widget.service.recordPayment(
          widget.bookingId,
          amount: amount,
          method: _method,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.summary;
    return AlertDialog(
      title: Text(widget.isRefund ? 'Issue refund' : 'Record payment'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (summary != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  widget.isRefund
                      ? 'Paid so far: ${formatMoney(summary.amountPaid)}'
                      : 'Remaining balance: ${formatMoney(summary.remainingBalance)}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount (£)',
                prefixText: '£ ',
              ),
            ),
            if (!widget.isRefund) ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _method,
                decoration: const InputDecoration(labelText: 'Method'),
                items: [
                  for (final m in _methods)
                    DropdownMenuItem(value: m, child: Text(m)),
                ],
                onChanged: (value) =>
                    setState(() => _method = value ?? _method),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Note (optional)'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 120,
          child: PrimaryButton(
            label: widget.isRefund ? 'Refund' : 'Record',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
