import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/dashboard.dart';
import 'status_chip.dart';

/// Upcoming trip with the travel countdown.
class TripHeroCard extends StatelessWidget {
  const TripHeroCard({super.key, required this.trip, this.onTap});

  final UpcomingTrip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final days = trip.daysUntilTravel;
    final bigText = days <= 0 ? 'Today' : '$days';
    final smallText = days <= 0
        ? 'departure day'
        : (days == 1 ? 'day to go' : 'days to go');
    final city = trip.departureCity;
    final dates = formatDateRange(trip.travelDate, trip.returnDate);
    final detail = (city == null || city.isEmpty)
        ? dates
        : '$dates  |  from $city';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'UPCOMING TRIP',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Spacer(),
                StatusChip(status: trip.status, onDark: true),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              trip.destination,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail,
              style: TextStyle(
                color: Colors.white.withAlpha(230),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 92),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    children: [
                      Text(
                        bigText,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        smallText,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking reference',
                        style: TextStyle(
                          color: Colors.white.withAlpha(200),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        trip.bookingReference,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
