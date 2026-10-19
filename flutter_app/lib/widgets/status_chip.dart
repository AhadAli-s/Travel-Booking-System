import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';

/// Coloured pill for a booking, payment or ticket status.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status, this.onDark = false});

  final String status;

  /// Use a white pill when the chip sits on a coloured hero card.
  final bool onDark;

  static Color colorFor(String status) {
    switch (status) {
      case 'PaymentReceived':
      case 'Confirmed':
      case 'DocumentsIssued':
      case 'ReadyToTravel':
      case 'TravelCompleted':
      case 'FullyPaid':
      case 'Resolved':
        return AppColors.success;
      case 'Pending':
      case 'Processing':
      case 'AwaitingPayment':
      case 'DocumentsPending':
      case 'PartiallyPaid':
      case 'InProgress':
      case 'WaitingForCustomer':
      case 'Open':
        return const Color(0xFF8A6D00);
      case 'Cancelled':
      case 'Unpaid':
        return AppColors.danger;
      default:
        return AppColors.cyanDark;
    }
  }

  static Color tintFor(String status) {
    switch (status) {
      case 'PaymentReceived':
      case 'Confirmed':
      case 'DocumentsIssued':
      case 'ReadyToTravel':
      case 'TravelCompleted':
      case 'FullyPaid':
      case 'Resolved':
        return AppColors.successTint;
      case 'Pending':
      case 'Processing':
      case 'AwaitingPayment':
      case 'DocumentsPending':
      case 'PartiallyPaid':
      case 'InProgress':
      case 'WaitingForCustomer':
      case 'Open':
        return AppColors.yellowTint;
      case 'Cancelled':
      case 'Unpaid':
        return AppColors.dangerTint;
      default:
        return AppColors.cyanTint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: onDark ? Colors.white : tintFor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: colorFor(status),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
