import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import '../models/booking.dart';
import 'status_chip.dart';

/// One booking in the My Bookings list.
class BookingCard extends StatelessWidget {
  const BookingCard({super.key, required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final payment = booking.payment;
    String paymentText = '';
    Color paymentColor = AppColors.muted;
    if (payment != null) {
      if (payment.remainingBalance <= 0) {
        paymentText = 'Paid in full';
        paymentColor = AppColors.success;
      } else {
        paymentText = '${formatMoney(payment.remainingBalance)} to pay';
        paymentColor = AppColors.pink;
      }
    }

    final city = booking.departureCity;
    final dates = formatDateRange(booking.travelDate, booking.returnDate);
    final subtitle = (city == null || city.isEmpty)
        ? dates
        : '$dates  |  from $city';

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      booking.destination,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(status: booking.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.muted, fontSize: 14),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 18,
                    color: AppColors.cyanDark,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    booking.bookingReference,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    paymentText,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: paymentColor,
                      fontSize: 14,
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
