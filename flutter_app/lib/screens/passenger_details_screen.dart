import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/info_row.dart';

/// Screen 10: travellers on the booking. Passport numbers stay hidden until the
/// customer taps a traveller, and even then they are masked until "Show" is pressed.
class PassengerDetailsScreen extends StatefulWidget {
  const PassengerDetailsScreen({
    super.key,
    required this.bookingId,
    required this.totalTravellers,
    this.guest = false,
    this.guestPassengers = const <Passenger>[],
  });

  final int bookingId;
  final int totalTravellers;
  final bool guest;
  final List<Passenger> guestPassengers;

  @override
  State<PassengerDetailsScreen> createState() => _PassengerDetailsScreenState();
}

class _PassengerDetailsScreenState extends State<PassengerDetailsScreen> {
  late final BookingService _service;
  late Future<List<Passenger>> _future;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
    _future = _load();
  }

  Future<List<Passenger>> _load() {
    if (widget.guest)
      return Future<List<Passenger>>.value(widget.guestPassengers);
    return _service.passengers(widget.bookingId);
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

  void _showDetail(Passenger passenger) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (_) => _PassengerSheet(
        passenger: passenger,
        detailFuture: _service.passengerDetail(widget.bookingId, passenger.id),
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
          'Passengers',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<List<Passenger>>(
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
          final passengers = snapshot.data!;
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
                      children: [
                        if (passengers.isEmpty)
                          const EmptyState(
                            icon: Icons.people_outline,
                            title: 'No passengers added yet',
                            message: 'Traveller details appear here once they have been added to your booking.',
                          )
                        else
                          for (final passenger in passengers) ...[
                            _PassengerCard(
                              passenger: passenger,
                              onTap: widget.guest
                                  ? null
                                  : () => _showDetail(passenger),
                            ),
                            const SizedBox(height: 10),
                          ],
                        if (passengers.isNotEmpty &&
                            passengers.length < widget.totalTravellers)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.yellowTint,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${passengers.length} of ${widget.totalTravellers} travellers added. '
                              'Contact the agency to add the rest.',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                widget.guest
                                    ? 'Log in to see passport and preference details.'
                                    : 'Passport details are protected. Only you and the agency can see them.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
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

class _PassengerCard extends StatelessWidget {
  const _PassengerCard({required this.passenger, required this.onTap});

  final Passenger passenger;
  final VoidCallback? onTap;

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
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.pinkTint,
                child: Text(
                  passenger.initials,
                  style: const TextStyle(
                    color: AppColors.pinkDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${passenger.passengerType}  |  Born ${formatDate(passenger.dateOfBirth)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassengerSheet extends StatefulWidget {
  const _PassengerSheet({required this.passenger, required this.detailFuture});

  final Passenger passenger;
  final Future<Passenger> detailFuture;

  @override
  State<_PassengerSheet> createState() => _PassengerSheetState();
}

class _PassengerSheetState extends State<_PassengerSheet> {
  bool _reveal = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.passenger;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FutureBuilder<Passenger>(
          future: widget.detailFuture,
          builder: (context, snapshot) {
            final detail = snapshot.data;
            final loading = snapshot.connectionState != ConnectionState.done;
            final failed = snapshot.hasError;

            final passport = detail?.passportNumber;
            final hasPassport = passport != null && passport.isNotEmpty;
            final String passportText;
            if (loading) {
              passportText = 'Loading...';
            } else if (failed) {
              passportText = 'Unavailable';
            } else if (!hasPassport) {
              passportText = 'Not provided';
            } else {
              passportText = _reveal ? (passport ?? '') : maskSecret(passport);
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  base.fullName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                InfoRow(label: 'Type', value: base.passengerType),
                InfoRow(
                  label: 'Date of birth',
                  value: formatDate(base.dateOfBirth),
                ),
                InfoRow(
                  label: 'Passport number',
                  valueWidget: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        passportText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                          letterSpacing: 1,
                        ),
                      ),
                      if (hasPassport)
                        IconButton(
                          tooltip: _reveal ? 'Hide' : 'Show',
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            _reveal
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _reveal = !_reveal),
                        ),
                    ],
                  ),
                ),
                InfoRow(
                  label: 'Passport expiry',
                  value: formatDate(detail?.passportExpiry),
                ),
                InfoRow(
                  label: 'Special assistance',
                  value: detail?.specialAssistance ?? base.specialAssistance,
                ),
                InfoRow(
                  label: 'Meal preference',
                  value: detail?.mealPreference ?? base.mealPreference,
                ),
                InfoRow(
                  label: 'Baggage',
                  value: detail?.baggage ?? base.baggage,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
