import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import '../widgets/empty_state.dart';
import '../widgets/info_row.dart';
import '../widgets/section_card.dart';

/// Screen 9: hotel, room and board basis.
class HotelDetailsScreen extends StatelessWidget {
  const HotelDetailsScreen({
    super.key,
    required this.hotel,
    required this.fallbackNights,
  });

  final HotelInfo? hotel;

  /// Used when the hotel has no check-in and check-out dates yet.
  final int fallbackNights;

  @override
  Widget build(BuildContext context) {
    final h = hotel;
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Hotel details',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: h == null
          ? const Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.hotel_outlined,
                  title: 'Hotel not confirmed yet',
                  message: 'Your hotel details appear here as soon as the agency confirms them.',
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
                        _HotelHeader(hotel: h),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Your stay',
                          icon: Icons.bed_outlined,
                          children: [
                            InfoRow(label: 'Room type', value: h.roomType),
                            InfoRow(
                              label: 'Rooms',
                              value: h.numRooms > 0 ? '${h.numRooms}' : null,
                            ),
                            InfoRow(label: 'Board basis', value: h.boardBasis),
                            InfoRow(
                              label: 'Check-in',
                              value: formatDate(h.checkInDate),
                            ),
                            InfoRow(
                              label: 'Check-out',
                              value: formatDate(h.checkOutDate),
                            ),
                            InfoRow(label: 'Nights', value: '${_nights(h)}'),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SectionCard(
                          title: 'Confirmation',
                          icon: Icons.verified_outlined,
                          children: [
                            InfoRow(
                              label: 'Hotel confirmation',
                              value: h.confirmationNumber,
                              bold: true,
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 6, bottom: 4),
                              child: Text(
                                'Show this number at reception when you check in.',
                                style: TextStyle(
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
  }

  int _nights(HotelInfo h) {
    final checkIn = h.checkInDate;
    final checkOut = h.checkOutDate;
    if (checkIn == null || checkOut == null) return fallbackNights;
    return DateTime.utc(
      checkOut.year,
      checkOut.month,
      checkOut.day,
    ).difference(DateTime.utc(checkIn.year, checkIn.month, checkIn.day)).inDays;
  }
}

class _HotelHeader extends StatelessWidget {
  const _HotelHeader({required this.hotel});

  final HotelInfo hotel;

  @override
  Widget build(BuildContext context) {
    final address = hotel.hotelAddress;
    final board = hotel.boardBasis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan, AppColors.cyanDark],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (board != null && board.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                board.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            hotel.hotelName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      color: Colors.white.withAlpha(240),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
