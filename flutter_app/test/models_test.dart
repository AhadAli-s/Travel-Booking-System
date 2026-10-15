import 'package:flutter_test/flutter_test.dart';
import 'package:travel_booking_app/core/format.dart';
import 'package:travel_booking_app/core/validators.dart';
import 'package:travel_booking_app/models/customer.dart';
import 'package:travel_booking_app/models/dashboard.dart';

void main() {
  group('DashboardData.fromJson', () {
    test('parses a full dashboard response', () {
      final data = DashboardData.fromJson({
        'upcomingTrip': {
          'bookingId': 7,
          'bookingReference': 'TB-7F3K9Q',
          'destination': 'Antalya, Turkey',
          'departureCity': 'Manchester',
          'travelDate': '2026-10-12',
          'returnDate': '2026-10-19',
          'status': 'Confirmed',
          'daysUntilTravel': 12,
        },
        'payment': {
          'totalPackagePrice': 2450,
          'amountPaid': '1000.00',
          'remainingBalance': 1450,
          'paymentDueDate': '2026-10-15',
          'paymentStatus': 'PartiallyPaid',
        },
        'documents': {'available': 6},
        'support': {'activeTickets': 1},
      });

      expect(data.trip!.destination, 'Antalya, Turkey');
      expect(data.trip!.daysUntilTravel, 12);
      expect(data.trip!.travelDate, DateTime(2026, 10, 12));
      expect(data.payment!.amountPaid, 1000.0);
      expect(data.payment!.remainingBalance, 1450.0);
      expect(data.documentsAvailable, 6);
      expect(data.activeTickets, 1);
    });

    test('handles a customer with no upcoming trip', () {
      final data = DashboardData.fromJson({
        'upcomingTrip': null,
        'payment': null,
        'documents': {'available': 0},
        'support': {'activeTickets': 0},
      });

      expect(data.trip, isNull);
      expect(data.payment, isNull);
      expect(data.documentsAvailable, 0);
    });
  });

  group('Customer', () {
    test('firstName returns the first word of the full name', () {
      final customer = Customer.fromJson({
        'id': 1,
        'fullName': 'Ahad Ali',
        'email': 'a@b.com',
      });
      expect(customer.firstName, 'Ahad');
      expect(customer.phone, isNull);
    });
  });

  group('formatters', () {
    test('formatMoney', () {
      expect(formatMoney(1450), '£1,450');
      expect(formatMoney(1450.5), '£1,450.50');
    });

    test('formatDate and formatDateRange', () {
      expect(formatDate(DateTime(2026, 10, 15)), '15 Oct 2026');
      expect(formatDate(null), '-');
      expect(
        formatDateRange(DateTime(2026, 10, 12), DateTime(2026, 10, 19)),
        '12-19 Oct',
      );
      expect(
        formatDateRange(DateTime(2026, 10, 28), DateTime(2026, 11, 4)),
        '28 Oct - 4 Nov',
      );
    });

    test('statusLabel splits camel case', () {
      expect(statusLabel('AwaitingPayment'), 'Awaiting Payment');
      expect(statusLabel('Confirmed'), 'Confirmed');
      expect(statusLabel(null), '-');
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email('a@b.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('newPassword needs 8 characters', () {
      expect(Validators.newPassword('1234567'), isNotNull);
      expect(Validators.newPassword('12345678'), isNull);
    });

    test('phone is optional but checked when present', () {
      expect(Validators.phone(''), isNull);
      expect(Validators.phone('+44 7700 900123'), isNull);
      expect(Validators.phone('abc'), isNotNull);
    });

    test('matches compares with the original password', () {
      final validator = Validators.matches(() => 'secret123');
      expect(validator('secret123'), isNull);
      expect(validator('other'), isNotNull);
    });
  });
}
