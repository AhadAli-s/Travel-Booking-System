import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'booking_details_screen.dart';

/// Screen 6: all bookings in three tabs.
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  late final BookingService _service;
  late Future<BookingsOverview> _future;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
    _future = _service.myBookings();
  }

  Future<void> _refresh() async {
    final next = _service.myBookings();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  void _openBooking(Booking booking) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookingDetailsScreen(bookingId: booking.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        appBar: AppBar(
          backgroundColor: AppColors.pink,
          foregroundColor: Colors.white,
          title: const Text(
            'My bookings',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          bottom: const TabBar(
            indicatorColor: AppColors.yellow,
            labelColor: Colors.white,
            unselectedLabelColor: Color(0xB3FFFFFF),
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Active'),
              Tab(text: 'Previous'),
            ],
          ),
        ),
        body: FutureBuilder<BookingsOverview>(
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
            final overview = snapshot.data!;
            return TabBarView(
              children: [
                _BookingList(
                  bookings: overview.upcoming,
                  onRefresh: _refresh,
                  onOpen: _openBooking,
                  emptyTitle: 'No upcoming trips',
                  emptyMessage: 'Bookings made on the agency website appear here automatically.',
                ),
                _BookingList(
                  bookings: overview.active,
                  onRefresh: _refresh,
                  onOpen: _openBooking,
                  emptyTitle: 'Nothing in progress',
                  emptyMessage:
                      'Trips that are under way right now show up here.',
                ),
                _BookingList(
                  bookings: overview.previous,
                  onRefresh: _refresh,
                  onOpen: _openBooking,
                  emptyTitle: 'No past bookings',
                  emptyMessage:
                      'Completed and cancelled bookings are kept here.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookingList extends StatelessWidget {
  const _BookingList({
    required this.bookings,
    required this.onRefresh,
    required this.onOpen,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<Booking> bookings;
  final Future<void> Function() onRefresh;
  final void Function(Booking) onOpen;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.pink,
      onRefresh: onRefresh,
      child: bookings.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 40),
                EmptyState(
                  icon: Icons.luggage_outlined,
                  title: emptyTitle,
                  message: emptyMessage,
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: bookings.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final booking = bookings[index];
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 700),
                    child: BookingCard(
                      booking: booking,
                      onTap: () => onOpen(booking),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
