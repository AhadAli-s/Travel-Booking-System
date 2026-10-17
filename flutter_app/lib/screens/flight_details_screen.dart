import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

/// Screen 8: outbound and return flight.
class FlightDetailsScreen extends StatelessWidget {
  const FlightDetailsScreen({super.key, required this.flight});

  final FlightInfo? flight;

  @override
  Widget build(BuildContext context) {
    final f = flight;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Flight details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: f == null
          ? const Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.flight_takeoff,
                  title: 'Flights not confirmed yet',
                  message: 'Your flight details appear here as soon as the agency confirms them.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      children: [
                        _Route(
                          from: f.departureAirport,
                          to: f.arrivalAirport,
                          label: 'Outbound',
                        ),
                        const SizedBox(height: 12),
                        SectionCard(
                          title: 'Outbound flight',
                          icon: Icons.flight_takeoff,
                          children: [
                            InfoRow(label: 'Airline', value: f.airline),
                            InfoRow(
                              label: 'Flight number',
                              value: f.flightNumber,
                              bold: true,
                            ),
                            InfoRow(label: 'From', value: f.departureAirport),
                            InfoRow(label: 'To', value: f.arrivalAirport),
                            InfoRow(
                              label: 'Departs',
                              value: formatDateTimeUtc(f.departureTime),
                            ),
                            InfoRow(
                              label: 'Arrives',
                              value: formatDateTimeUtc(f.arrivalTime),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (f.hasReturnFlight) ...[
                          _Route(
                            from: f.arrivalAirport,
                            to: f.departureAirport,
                            label: 'Return',
                          ),
                          const SizedBox(height: 12),
                          SectionCard(
                            title: 'Return flight',
                            icon: Icons.flight_land,
                            children: [
                              InfoRow(label: 'Airline', value: f.airline),
                              InfoRow(
                                label: 'Flight number',
                                value: f.returnFlightNumber,
                                bold: true,
                              ),
                              InfoRow(label: 'From', value: f.arrivalAirport),
                              InfoRow(label: 'To', value: f.departureAirport),
                              InfoRow(
                                label: 'Departs',
                                value: formatDateTimeUtc(f.returnDepartureTime),
                              ),
                              InfoRow(
                                label: 'Arrives',
                                value: formatDateTimeUtc(f.returnArrivalTime),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        SectionCard(
                          title: 'Baggage allowance',
                          icon: Icons.luggage_outlined,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                (f.baggageAllowance == null ||
                                        f.baggageAllowance!.isEmpty)
                                    ? 'Baggage details have not been added yet.'
                                    : f.baggageAllowance!,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Times are local airport times as entered by the agency.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Big "MAN -> AYT" banner above each flight card.
class _Route extends StatelessWidget {
  const _Route({required this.from, required this.to, required this.label});

  final String from;
  final String to;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.pinkTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.pinkDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                from,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.flight, color: AppColors.pink, size: 28),
              const SizedBox(width: 14),
              Text(
                to,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
