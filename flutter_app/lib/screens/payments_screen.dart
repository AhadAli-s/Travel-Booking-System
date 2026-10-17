import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/payment.dart';
import '../services/booking_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';

/// Screen 11: price, balance, due date and payment history with receipts.
class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({
    super.key,
    required this.bookingId,
    required this.reference,
    this.guest = false,
    this.guestSummary,
  });

  final int bookingId;
  final String reference;
  final bool guest;
  final PaymentSummary? guestSummary;

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  late final BookingService _service;
  late Future<PaymentDetails?> _future;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
    _future = _load();
  }

  Future<PaymentDetails?> _load() async {
    if (widget.guest) {
      final summary = widget.guestSummary;
      if (summary == null) return null;
      return PaymentDetails(summary: summary, history: const <PaymentEntry>[]);
    }
    return _service.getPayment(widget.bookingId);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  void _showReceipt(PaymentEntry entry) {
    showDialog<void>(
      context: context,
      builder: (_) => _ReceiptDialog(
        future: _service.getReceipt(widget.bookingId, entry.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<PaymentDetails?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pink),
            );
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          final details = snapshot.data;
          if (details == null) {
            return const Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'No payment details yet',
                  message: 'The agency has not added a price for this booking.',
                ),
              ),
            );
          }
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SummaryCard(
                          reference: widget.reference,
                          summary: details.summary,
                        ),
                        const SizedBox(height: 16),
                        _buildHistory(details),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistory(PaymentDetails details) {
    if (widget.guest) {
      return SectionCard(
        title: 'Payment history',
        icon: Icons.history,
        children: const [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Log in to see your payment history and receipts.',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
          ),
        ],
      );
    }
    return SectionCard(
      title: 'Payment history',
      icon: Icons.history,
      children: details.history.isEmpty
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No payments have been recorded yet.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
            ]
          : [
              for (final entry in details.history)
                _HistoryTile(entry: entry, onTap: () => _showReceipt(entry)),
            ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.reference, required this.summary});

  final String reference;
  final PaymentSummary summary;

  @override
  Widget build(BuildContext context) {
    final total = summary.totalPackagePrice;
    final progress = total <= 0
        ? 0.0
        : (summary.amountPaid / total).clamp(0.0, 1.0);
    final due = summary.paymentDueDate;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                reference,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              StatusChip(status: summary.paymentStatus),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Remaining balance',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            summary.remainingBalance <= 0
                ? 'Paid in full'
                : formatMoney(summary.remainingBalance),
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: summary.remainingBalance <= 0
                  ? AppColors.success
                  : AppColors.pink,
            ),
          ),
          const SizedBox(height: 14),
          LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            color: AppColors.pink,
            backgroundColor: AppColors.pinkTint,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 14),
          InfoRow(label: 'Package price', value: formatMoney(total)),
          InfoRow(label: 'Amount paid', value: formatMoney(summary.amountPaid)),
          if (summary.remainingBalance > 0)
            InfoRow(
              label: 'Next payment due',
              value: due == null ? '-' : formatDate(due),
              valueWidget: due == null
                  ? null
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatDate(due),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        if (summary.isOverdue) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.dangerTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry, required this.onTap});

  final PaymentEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final refund = entry.isRefund;
    final amount = entry.amount.abs();
    final details = <String>[
      formatDate(entry.paymentDate?.toLocal()),
      if (entry.method != null && entry.method!.isNotEmpty) entry.method!,
      if (entry.note != null && entry.note!.isNotEmpty) entry.note!,
    ].join('  |  ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: refund ? AppColors.dangerTint : AppColors.successTint,
                shape: BoxShape.circle,
              ),
              child: Icon(
                refund ? Icons.arrow_upward : Icons.arrow_downward,
                size: 18,
                color: refund ? AppColors.danger : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    refund ? 'Refund' : 'Payment received',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${refund ? '-' : '+'}${formatMoney(amount)}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: refund ? AppColors.danger : AppColors.success,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ReceiptDialog extends StatelessWidget {
  const _ReceiptDialog({required this.future});

  final Future<Receipt> future;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment receipt'),
      content: SizedBox(
        width: 340,
        child: FutureBuilder<Receipt>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 90,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                ),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return Text(
                error is ApiException
                    ? error.message
                    : 'Could not load the receipt.',
              );
            }
            final r = snapshot.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InfoRow(label: 'Receipt', value: r.receiptNumber, bold: true),
                InfoRow(label: 'Booking', value: r.bookingReference),
                InfoRow(label: 'Destination', value: r.destination),
                InfoRow(
                  label: 'Amount',
                  value: formatMoney(r.amount.abs()),
                  bold: true,
                ),
                InfoRow(label: 'Method', value: r.method),
                InfoRow(
                  label: 'Date',
                  value: formatDate(r.paymentDate?.toLocal()),
                ),
                InfoRow(
                  label: 'Paid to date',
                  value: formatMoney(r.amountPaidToDate),
                ),
                InfoRow(
                  label: 'Remaining',
                  value: formatMoney(r.remainingBalance),
                ),
              ],
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
