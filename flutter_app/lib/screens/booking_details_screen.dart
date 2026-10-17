import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/booking_timeline.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../providers/auth_provider.dart';
import '../services/booking_service.dart';
import '../widgets/action_tile.dart';
import '../widgets/error_state.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';
import '../widgets/status_chip.dart';
import '../widgets/timeline_view.dart';
import 'documents_screen.dart';
import 'flight_details_screen.dart';
import 'hotel_details_screen.dart';
import 'passenger_details_screen.dart';
import 'payments_screen.dart';

/// Screen 7: everything about one booking.
/// Opened with a [bookingId] for a logged in customer, or with a booking found
/// through the public reference and email lookup (guest mode, read only).
class BookingDetailsScreen extends StatefulWidget {
  const BookingDetailsScreen({super.key, required this.bookingId})
    : guestBooking = null;

  const BookingDetailsScreen.guest({super.key, required Booking booking})
    : bookingId = null,
      guestBooking = booking;

  final int? bookingId;
  final Booking? guestBooking;

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late final BookingService _service;
  late Future<Booking> _future;

  bool get _isGuest => widget.guestBooking != null;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
    _future = _load();
  }

  Future<Booking> _load() {
    final guest = widget.guestBooking;
    if (guest != null) return Future<Booking>.value(guest);
    return _service.getBooking(widget.bookingId!);
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

  void _open(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Booking details',
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
            return ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: _buildBody(snapshot.data!),
          );
        },
      ),
    );
  }

  Widget _buildBody(Booking booking) {
    final payment = booking.payment;
    String paymentSubtitle = 'No payment details yet';
    if (payment != null) {
      paymentSubtitle = payment.remainingBalance <= 0
          ? 'Paid in full'
          : '${formatMoney(payment.remainingBalance)} remaining';
    }

    final flight = booking.flight;
    final hotel = booking.hotel;
    final customerName =
        booking.customerName ?? context.read<AuthProvider>().customer?.fullName;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isGuest) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.yellowTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'You are viewing this booking with its reference and email. Log in to see payment history and download documents.',
                      style: TextStyle(fontSize: 13, color: AppColors.ink),
                    ),
                  ),
                ],
                _Header(booking: booking),
                const SizedBox(height: 16),
                if (booking.isCancelled)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.dangerTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: AppColors.danger),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This booking has been cancelled. Contact the agency if you have any questions.',
                            style: TextStyle(
                              color: AppColors.danger,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                  title: 'Booking information',
                  icon: Icons.assignment_outlined,
                  children: [
                    InfoRow(
                      label: 'Reference',
                      value: booking.bookingReference,
                      bold: true,
                    ),
                    InfoRow(
                      label: 'Booked on',
                      value: formatDate(booking.bookingDate?.toLocal()),
                    ),
                    InfoRow(
                      label: 'Status',
                      valueWidget: StatusChip(status: booking.status),
                    ),
                    InfoRow(label: 'Customer', value: customerName),
                    InfoRow(
                      label: 'Travellers',
                      value: travellersLabel(
                        booking.numAdults,
                        booking.numChildren,
                        booking.numInfants,
                      ),
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
                    InfoRow(label: 'Airport', value: booking.departureAirport),
                    InfoRow(
                      label: 'Travel date',
                      value: formatDate(booking.travelDate),
                    ),
                    InfoRow(
                      label: 'Return date',
                      value: formatDate(booking.returnDate),
                    ),
                    InfoRow(label: 'Nights', value: '${booking.numNights}'),
                  ],
                ),
                const SizedBox(height: 16),
                _TransferCard(transfer: booking.transfer),
                const SizedBox(height: 16),
                ActionTile(
                  icon: Icons.flight_takeoff,
                  title: 'Flight details',
                  subtitle: flight == null
                      ? 'Not confirmed yet'
                      : '${flight.airline} ${flight.flightNumber}  |  ${flight.departureAirport} to ${flight.arrivalAirport}',
                  onTap: () => _open(FlightDetailsScreen(flight: flight)),
                ),
                const SizedBox(height: 10),
                ActionTile(
                  icon: Icons.hotel_outlined,
                  title: 'Hotel details',
                  subtitle: hotel == null
                      ? 'Not confirmed yet'
                      : hotel.hotelName,
                  accent: AppColors.cyanDark,
                  tint: AppColors.cyanTint,
                  onTap: () => _open(
                    HotelDetailsScreen(
                      hotel: hotel,
                      fallbackNights: booking.numNights,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ActionTile(
                  icon: Icons.people_outline,
                  title: 'Passengers',
                  subtitle: travellersLabel(
                    booking.numAdults,
                    booking.numChildren,
                    booking.numInfants,
                  ),
                  onTap: () => _open(
                    PassengerDetailsScreen(
                      bookingId: booking.id,
                      totalTravellers: booking.totalTravellers,
                      guest: _isGuest,
                      guestPassengers: booking.passengers,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ActionTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Payments',
                  subtitle: paymentSubtitle,
                  onTap: () => _open(
                    PaymentsScreen(
                      bookingId: booking.id,
                      reference: booking.bookingReference,
                      guest: _isGuest,
                      guestSummary: booking.payment,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ActionTile(
                  icon: Icons.description_outlined,
                  title: 'Travel documents',
                  subtitle: booking.documents.isEmpty
                      ? 'None issued yet'
                      : '${booking.documents.length} available',
                  accent: AppColors.cyanDark,
                  tint: AppColors.cyanTint,
                  onTap: () => _open(
                    DocumentsScreen(
                      bookingId: booking.id,
                      guest: _isGuest,
                      guestDocuments: booking.documents,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final days = booking.daysUntilTravel;
    final showCountdown =
        days != null &&
        days >= 0 &&
        !booking.isCancelled &&
        statusRank(booking.status) < 8;
    final countdownText = days == 0
        ? 'Departing today'
        : (days == 1 ? '1 day to go' : '$days days to go');

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
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatDateRange(booking.travelDate, booking.returnDate)}  |  ${booking.numNights} nights',
            style: TextStyle(color: Colors.white.withAlpha(230), fontSize: 15),
          ),
          if (showCountdown) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                countdownText,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.transfer});

  final TransferInfo? transfer;

  @override
  Widget build(BuildContext context) {
    final t = transfer;
    return SectionCard(
      title: 'Airport transfer',
      icon: Icons.airport_shuttle_outlined,
      trailing: t == null ? null : StatusChip(status: t.transferStatus),
      children: t == null
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No transfer is booked for this trip.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ),
            ]
          : [
              InfoRow(label: 'Pick-up', value: t.pickupLocation),
              InfoRow(
                label: 'Pick-up time',
                value: formatDateTimeUtc(t.pickupTime),
              ),
              InfoRow(label: 'Drop-off', value: t.dropoffLocation),
            ],
    );
  }
}
