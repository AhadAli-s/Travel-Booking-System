import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/admin_meta.dart';
import '../core/format.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/admin_booking_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/search_field.dart';
import '../widgets/status_chip.dart';
import 'admin_booking_detail_screen.dart';

/// Screen 19: booking management. Filter by status, search locally by
/// reference, destination or customer, then open a booking to manage it.
class AdminBookingsScreen extends StatefulWidget {
  const AdminBookingsScreen({super.key});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  late final AdminBookingService _service;
  late Future<List<Booking>> _future;
  String? _statusFilter;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = AdminBookingService(context.read<StaffApiClient>().api);
    _future = _service.list();
  }

  void _load() {
    setState(() => _future = _service.list(status: _statusFilter));
  }

  Future<void> _openBooking(Booking booking) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminBookingDetailScreen(bookingId: booking.id),
      ),
    );
    _load();
  }

  List<Booking> _filtered(List<Booking> bookings) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return bookings;
    return bookings.where((b) {
      return b.bookingReference.toLowerCase().contains(query) ||
          b.destination.toLowerCase().contains(query) ||
          (b.customerName ?? '').toLowerCase().contains(query) ||
          (b.customerEmail ?? '').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchField(
                hint: 'Search by reference, destination or customer',
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == null,
                      onTap: () {
                        _statusFilter = null;
                        _load();
                      },
                    ),
                    for (final status in bookingStatuses)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _FilterChip(
                          label: statusLabel(status),
                          selected: _statusFilter == status,
                          onTap: () {
                            _statusFilter = status;
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<Booking>>(
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
                        onRetry: () async => _load(),
                      );
                    }
                    final bookings = _filtered(snapshot.data!);
                    if (bookings.isEmpty) {
                      return const EmptyState(
                        icon: Icons.luggage_outlined,
                        title: 'No bookings found',
                        message: 'Try a different filter or search.',
                      );
                    }
                    return ListView.separated(
                      itemCount: bookings.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _BookingTile(
                        booking: bookings[index],
                        onTap: () => _openBooking(bookings[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.pinkTint,
      labelStyle: TextStyle(
        color: selected ? AppColors.pinkDark : AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(color: selected ? AppColors.pink : AppColors.border),
      backgroundColor: Colors.white,
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          booking.bookingReference,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(status: booking.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.destination,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${booking.customerName ?? ''}  |  ${formatDateRange(booking.travelDate, booking.returnDate)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Icon(
                    booking.assignedStaff == null
                        ? Icons.person_off_outlined
                        : Icons.person,
                    size: 16,
                    color: booking.assignedStaff == null
                        ? AppColors.muted
                        : AppColors.cyanDark,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    booking.assignedStaff?.firstName ?? 'Unassigned',
                    style: TextStyle(
                      fontSize: 11,
                      color: booking.assignedStaff == null
                          ? AppColors.muted
                          : AppColors.cyanDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
