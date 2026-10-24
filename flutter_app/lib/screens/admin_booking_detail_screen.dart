import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/admin_meta.dart';
import '../core/api_client.dart';
import '../core/booking_timeline.dart';
import '../core/format.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../models/payment.dart';
import '../providers/staff_auth_provider.dart';
import '../services/admin_booking_service.dart';
import '../services/admin_document_service.dart';
import '../services/admin_staff_service.dart';
import '../services/booking_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/error_state.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/timeline_view.dart';
import 'admin_booking_edit_dialogs.dart';
import 'admin_booking_segment_dialogs.dart';
import 'admin_document_upload_dialog.dart';
import 'admin_payment_dialogs.dart';

/// Staff view of a booking: edit details, change status, assign staff, edit
/// flight/hotel/transfer, record payments and refunds, and manage documents.
/// GET /bookings/:id for staff returns the exact same shape as Booking.fromJson
/// already parses, so this reuses the Booking model from the customer app.
class AdminBookingDetailScreen extends StatefulWidget {
  const AdminBookingDetailScreen({super.key, required this.bookingId});

  final int bookingId;

  @override
  State<AdminBookingDetailScreen> createState() =>
      _AdminBookingDetailScreenState();
}

class _AdminBookingDetailScreenState extends State<AdminBookingDetailScreen> {
  late final AdminBookingService _bookingService;
  late final AdminStaffService _staffService;
  late final AdminDocumentService _documentService;
  late final BookingService _readService;
  late Future<Booking> _future;
  late Future<PaymentDetails> _paymentFuture;

  @override
  void initState() {
    super.initState();
    final api = context.read<StaffApiClient>().api;
    _bookingService = AdminBookingService(api);
    _staffService = AdminStaffService(api);
    _documentService = AdminDocumentService(api);
    _readService = BookingService(api);
    _future = _bookingService.getBooking(widget.bookingId);
    _paymentFuture = _readService.getPayment(widget.bookingId);
  }

  void _refresh() {
    setState(() {
      _future = _bookingService.getBooking(widget.bookingId);
      _paymentFuture = _readService.getPayment(widget.bookingId);
    });
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _recordPayment(int bookingId) async {
    final summary = (await _paymentFuture).summary;
    if (!mounted) return;
    final changed = await showRecordPaymentDialog(
      context,
      _bookingService,
      bookingId,
      summary,
    );
    if (changed == true) _refresh();
  }

  Future<void> _issueRefund(int bookingId) async {
    final summary = (await _paymentFuture).summary;
    if (!mounted) return;
    final changed = await showIssueRefundDialog(
      context,
      _bookingService,
      bookingId,
      summary,
    );
    if (changed == true) _refresh();
  }

  Future<void> _deleteDocument(int documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete document?'),
        content: const Text(
          'This removes the file from the customer\'s account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _documentService.delete(documentId);
      _refresh();
    } on ApiException catch (e) {
      _message(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<StaffAuthProvider>().staff?.role ?? '';
    final canEditBooking = roleCanEditBookings(role);
    final canManagePayments = roleCanManagePayments(role);
    final canManageDocuments = roleCanManageDocuments(role);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<Booking>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pink),
            );
          }
          if (snapshot.hasError) {
            return ErrorState(
              error: snapshot.error,
              onRetry: () async => _refresh(),
            );
          }
          final booking = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: () async => _refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(booking: booking),
                        const SizedBox(height: 16),
                        if (canEditBooking)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final changed =
                                        await showChangeStatusDialog(
                                          context,
                                          _bookingService,
                                          booking,
                                        );
                                    if (changed == true) _refresh();
                                  },
                                  icon: const Icon(
                                    Icons.flag_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Status'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final changed = await showAssignStaffDialog(
                                      context,
                                      _bookingService,
                                      _staffService,
                                      booking,
                                    );
                                    if (changed == true) _refresh();
                                  },
                                  icon: const Icon(
                                    Icons.person_add_alt_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Assign'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    final changed = await showEditBookingDialog(
                                      context,
                                      _bookingService,
                                      booking,
                                    );
                                    if (changed == true) _refresh();
                                  },
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 18,
                                  ),
                                  label: const Text('Edit'),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Booking progress',
                          icon: Icons.route_outlined,
                          children: [
                            const SizedBox(height: 8),
                            TimelineView(steps: buildTimeline(booking.status)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Customer',
                          icon: Icons.person_outline,
                          children: [
                            InfoRow(
                              label: 'Name',
                              value: booking.customerName,
                              bold: true,
                            ),
                            InfoRow(
                              label: 'Email',
                              value: booking.customerEmail,
                            ),
                            InfoRow(
                              label: 'Travellers',
                              value: travellersLabel(
                                booking.numAdults,
                                booking.numChildren,
                                booking.numInfants,
                              ),
                            ),
                            InfoRow(
                              label: 'Assigned to',
                              value:
                                  booking.assignedStaff?.fullName ??
                                  'Unassigned',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Destination',
                          icon: Icons.place_outlined,
                          children: [
                            InfoRow(
                              label: 'Destination',
                              value: booking.destination,
                              bold: true,
                            ),
                            InfoRow(
                              label: 'Departing from',
                              value: booking.departureCity,
                            ),
                            InfoRow(
                              label: 'Airport',
                              value: booking.departureAirport,
                            ),
                            InfoRow(
                              label: 'Travel date',
                              value: formatDate(booking.travelDate),
                            ),
                            InfoRow(
                              label: 'Return date',
                              value: formatDate(booking.returnDate),
                            ),
                            InfoRow(
                              label: 'Nights',
                              value: '${booking.numNights}',
                            ),
                            if (booking.notes != null &&
                                booking.notes!.isNotEmpty)
                              InfoRow(label: 'Notes', value: booking.notes),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ActionTile(
                          icon: Icons.flight_takeoff,
                          title: 'Flight',
                          subtitle: booking.flight == null
                              ? 'Not set — tap to add'
                              : '${booking.flight!.airline} ${booking.flight!.flightNumber}  |  ${booking.flight!.departureAirport} to ${booking.flight!.arrivalAirport}',
                          onTap: canEditBooking
                              ? () async {
                                  final saved = await showEditFlightDialog(
                                    context,
                                    _bookingService,
                                    booking.id,
                                    booking.flight,
                                  );
                                  if (saved == true) _refresh();
                                }
                              : null,
                        ),
                        const SizedBox(height: 10),
                        ActionTile(
                          icon: Icons.hotel_outlined,
                          title: 'Hotel',
                          subtitle:
                              booking.hotel?.hotelName ??
                              'Not set — tap to add',
                          accent: AppColors.cyanDark,
                          tint: AppColors.cyanTint,
                          onTap: canEditBooking
                              ? () async {
                                  final saved = await showEditHotelDialog(
                                    context,
                                    _bookingService,
                                    booking.id,
                                    booking.hotel,
                                  );
                                  if (saved == true) _refresh();
                                }
                              : null,
                        ),
                        const SizedBox(height: 10),
                        ActionTile(
                          icon: Icons.airport_shuttle_outlined,
                          title: 'Airport transfer',
                          subtitle: booking.transfer == null
                              ? 'Not set — tap to add'
                              : '${statusLabel(booking.transfer!.transferStatus)}  |  ${booking.transfer!.pickupLocation ?? '-'}',
                          onTap: canEditBooking
                              ? () async {
                                  final saved = await showEditTransferDialog(
                                    context,
                                    _bookingService,
                                    booking.id,
                                    booking.transfer,
                                  );
                                  if (saved == true) _refresh();
                                }
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (booking.passengers.isNotEmpty)
                          SectionCard(
                            title: 'Passengers (${booking.passengers.length})',
                            icon: Icons.people_outline,
                            children: [
                              for (final p in booking.passengers)
                                InfoRow(
                                  label: p.passengerType,
                                  value: p.fullName,
                                ),
                            ],
                          ),
                        const SizedBox(height: 16),
                        _PaymentSection(
                          future: _paymentFuture,
                          canManage: canManagePayments,
                          onRecord: () => _recordPayment(booking.id),
                          onRefund: () => _issueRefund(booking.id),
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Documents (${booking.documents.length})',
                          icon: Icons.description_outlined,
                          trailing: canManageDocuments
                              ? TextButton.icon(
                                  onPressed: () async {
                                    final uploaded =
                                        await showUploadDocumentDialog(
                                          context,
                                          _documentService,
                                          booking.id,
                                        );
                                    if (uploaded == true) _refresh();
                                  },
                                  icon: const Icon(Icons.upload_file, size: 18),
                                  label: const Text('Upload'),
                                )
                              : null,
                          children: booking.documents.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      'No documents uploaded yet.',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  for (final doc in booking.documents)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            documentTypeIcon(doc.documentType),
                                            size: 18,
                                            color: AppColors.cyanDark,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              documentTypeLabel(
                                                doc.documentType,
                                              ),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                          ),
                                          if (canManageDocuments)
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete_outline,
                                                color: AppColors.danger,
                                                size: 20,
                                              ),
                                              onPressed: () =>
                                                  _deleteDocument(doc.id),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                        ),
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
}

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.pink, AppColors.pinkDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                booking.bookingReference,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              StatusChip(status: booking.status, onDark: true),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            booking.destination,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatDateRange(booking.travelDate, booking.returnDate)}  |  ${booking.numNights} nights',
            style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _PaymentSection extends StatelessWidget {
  const _PaymentSection({
    required this.future,
    required this.canManage,
    required this.onRecord,
    required this.onRefund,
  });

  final Future<PaymentDetails> future;
  final bool canManage;
  final VoidCallback onRecord;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PaymentDetails>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SectionCard(
            title: 'Payment',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                ),
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return const SectionCard(
            title: 'Payment',
            icon: Icons.account_balance_wallet_outlined,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Could not load payment details.',
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ],
          );
        }
        final details = snapshot.data!;
        final summary = details.summary;
        return SectionCard(
          title: 'Payment',
          icon: Icons.account_balance_wallet_outlined,
          trailing: StatusChip(status: summary.paymentStatus),
          children: [
            InfoRow(
              label: 'Package price',
              value: formatMoney(summary.totalPackagePrice),
            ),
            InfoRow(
              label: 'Amount paid',
              value: formatMoney(summary.amountPaid),
              bold: true,
            ),
            InfoRow(
              label: 'Remaining',
              value: formatMoney(summary.remainingBalance),
            ),
            if (summary.paymentDueDate != null)
              InfoRow(
                label: 'Due date',
                value: formatDate(summary.paymentDueDate),
              ),
            if (canManage) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onRecord,
                      icon: const Icon(Icons.add_card_outlined, size: 18),
                      label: const Text('Record payment'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: summary.amountPaid > 0 ? onRefund : null,
                      icon: const Icon(Icons.undo, size: 18),
                      label: const Text('Refund'),
                    ),
                  ),
                ],
              ),
            ],
            if (details.history.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 6),
              for (final entry in details.history)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(
                        entry.isRefund
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 16,
                        color: entry.isRefund
                            ? AppColors.danger
                            : AppColors.success,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.isRefund ? '-' : '+'}${formatMoney(entry.amount.abs())}  ${entry.method ?? ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        formatDate(entry.paymentDate?.toLocal()),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}
