import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../core/ticket_meta.dart';
import '../models/admin_customer.dart';
import '../models/booking.dart';
import '../models/contact_note.dart';
import '../models/ticket.dart';
import '../services/admin_customer_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import 'admin_booking_detail_screen.dart';
import 'admin_ticket_thread_screen.dart';

/// One customer's bookings, tickets and contact history, with a button to
/// log a new contact note. Any staff role can view and add notes.
class AdminCustomerDetailScreen extends StatefulWidget {
  const AdminCustomerDetailScreen({super.key, required this.customerId});

  final int customerId;

  @override
  State<AdminCustomerDetailScreen> createState() =>
      _AdminCustomerDetailScreenState();
}

class _AdminCustomerDetailScreenState extends State<AdminCustomerDetailScreen> {
  late final AdminCustomerService _service;
  late Future<AdminCustomerDetail> _future;

  @override
  void initState() {
    super.initState();
    _service = AdminCustomerService(context.read<StaffApiClient>().api);
    _future = _service.detail(widget.customerId);
  }

  Future<void> _refresh() async {
    final next = _service.detail(widget.customerId);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  Future<void> _openBooking(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminBookingDetailScreen(bookingId: booking.id),
      ),
    );
    _refresh();
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTicketThreadScreen(ticketId: ticket.id),
      ),
    );
    _refresh();
  }

  Future<void> _addNote(List<Booking> bookings) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => _AddNoteDialog(
        service: _service,
        customerId: widget.customerId,
        bookings: bookings,
      ),
    );
    if (added == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Customer',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<AdminCustomerDetail>(
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
          final detail = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CustomerHeader(customer: detail.customer),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Bookings (${detail.bookings.length})',
                          icon: Icons.luggage_outlined,
                          children: detail.bookings.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      'No bookings yet.',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  for (final b in detail.bookings)
                                    _BookingRow(
                                      booking: b,
                                      onTap: () => _openBooking(b),
                                    ),
                                ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Support tickets (${detail.tickets.length})',
                          icon: Icons.support_agent_outlined,
                          children: detail.tickets.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      'No tickets.',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  for (final t in detail.tickets)
                                    _TicketRow(
                                      ticket: t,
                                      onTap: () => _openTicket(t),
                                    ),
                                ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title:
                              'Contact history (${detail.contactHistory.length})',
                          icon: Icons.history,
                          trailing: TextButton.icon(
                            onPressed: () => _addNote(detail.bookings),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add note'),
                          ),
                          children: detail.contactHistory.isEmpty
                              ? const [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      'No contact logged yet.',
                                      style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ]
                              : [
                                  for (final n in detail.contactHistory)
                                    _NoteRow(note: n),
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

class _CustomerHeader extends StatelessWidget {
  const _CustomerHeader({required this.customer});

  final CustomerSummary customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.pinkTint,
            child: Text(
              customer.fullName.isNotEmpty
                  ? customer.fullName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.pinkDark,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  customer.email,
                  style: const TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                if (customer.phone != null && customer.phone!.isNotEmpty)
                  Text(
                    customer.phone!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Customer since ${formatDate(customer.createdAt?.toLocal())}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingRow extends StatelessWidget {
  const _BookingRow({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.destination,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    '${booking.bookingReference}  |  ${formatDateRange(booking.travelDate, booking.returnDate)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(status: booking.status),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    ticketCategoryLabel(ticket.category),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(status: ticket.status),
            const Icon(Icons.chevron_right, color: AppColors.muted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({required this.note});

  final ContactNote note;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                note.channel == 'Phone'
                    ? Icons.phone_outlined
                    : note.channel == 'Email'
                    ? Icons.mail_outline
                    : note.channel == 'InPerson'
                    ? Icons.people_outline
                    : Icons.chat_bubble_outline,
                size: 16,
                color: AppColors.cyanDark,
              ),
              const SizedBox(width: 6),
              Text(
                note.channel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyanDark,
                ),
              ),
              const Spacer(),
              Text(
                formatDate(note.createdAt?.toLocal()),
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            note.note,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
          ),
          if (note.author != null) ...[
            const SizedBox(height: 2),
            Text(
              'by ${note.author!.fullName}',
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  const _AddNoteDialog({
    required this.service,
    required this.customerId,
    required this.bookings,
  });

  final AdminCustomerService service;
  final int customerId;
  final List<Booking> bookings;

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _controller = TextEditingController();
  String _channel = 'Phone';
  int? _bookingId;
  bool _loading = false;
  String? _error;

  static const _channels = ['Phone', 'Email', 'InApp', 'InPerson', 'Other'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final note = _controller.text.trim();
    if (note.isEmpty) {
      setState(() => _error = 'Enter a note');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.addNote(
        widget.customerId,
        note: note,
        channel: _channel,
        bookingId: _bookingId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add contact note'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _channel,
              decoration: const InputDecoration(labelText: 'Channel'),
              items: [
                for (final c in _channels)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (value) =>
                  setState(() => _channel = value ?? _channel),
            ),
            const SizedBox(height: 10),
            if (widget.bookings.isNotEmpty)
              DropdownButtonFormField<int?>(
                initialValue: _bookingId,
                decoration: const InputDecoration(
                  labelText: 'Related booking (optional)',
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('None')),
                  for (final b in widget.bookings)
                    DropdownMenuItem(
                      value: b.id,
                      child: Text(b.bookingReference),
                    ),
                ],
                onChanged: (value) => setState(() => _bookingId = value),
              ),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note',
                border: OutlineInputBorder(),
              ),
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
          width: 110,
          child: PrimaryButton(
            label: 'Save',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
