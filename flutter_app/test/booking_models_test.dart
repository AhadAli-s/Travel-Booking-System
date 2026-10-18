import 'package:flutter_test/flutter_test.dart';
import 'package:travel_booking_app/core/booking_timeline.dart';
import 'package:travel_booking_app/core/format.dart';
import 'package:travel_booking_app/models/booking.dart';
import 'package:travel_booking_app/models/payment.dart';

/// Shape taken from a real GET /api/bookings/:id response.
final Map<String, dynamic> _bookingJson = {
  'id': 69,
  'bookingReference': 'TB-PQUZ56',
  'bookingDate': '2026-10-15T18:16:33.386Z',
  'status': 'Confirmed',
  'numAdults': 2,
  'numChildren': 1,
  'numInfants': 0,
  'destination': 'Antalya, Turkey',
  'departureCity': 'Manchester',
  'departureAirport': 'MAN',
  'travelDate': '2026-11-04',
  'returnDate': '2026-11-11',
  'numNights': 7,
  'notes': null,
  'Customer': {'fullName': 'Shape Tester'},
  'Flight': {
    'airline': 'Jet2',
    'flightNumber': 'LS123',
    'departureAirport': 'MAN',
    'arrivalAirport': 'AYT',
    'departureTime': '2026-11-04T06:00:00.000Z',
    'arrivalTime': '2026-11-04T12:10:00.000Z',
    'returnFlightNumber': 'LS124',
    'returnDepartureTime': '2026-11-11T13:00:00.000Z',
    'returnArrivalTime': '2026-11-11T17:10:00.000Z',
    'baggageAllowance': '1 x 22kg hold bag',
  },
  'Hotel': {
    'hotelName': 'Sunrise Resort',
    'hotelAddress': 'Lara Beach, Antalya',
    'roomType': 'Double sea view',
    'numRooms': 1,
    'boardBasis': 'All Inclusive',
    'checkInDate': '2026-11-04',
    'checkOutDate': '2026-11-11',
    'confirmationNumber': 'HC-99812',
  },
  'Transfer': {
    'pickupLocation': 'Antalya Airport',
    'pickupTime': '2026-11-04T12:45:00.000Z',
    'dropoffLocation': 'Sunrise Resort',
    'transferStatus': 'Confirmed',
  },
  'Payment': {
    'totalPackagePrice': '2450.00',
    'amountPaid': '1000.00',
    'paymentDueDate': '2026-10-25',
    'paymentStatus': 'PartiallyPaid',
  },
  'Passengers': [
    {
      'id': 36,
      'fullName': 'Shape Tester',
      'dateOfBirth': '1990-01-01',
      'passengerType': 'Adult',
    },
    {
      'id': 37,
      'fullName': 'Kid Tester',
      'dateOfBirth': '2018-05-05',
      'passengerType': 'Child',
    },
  ],
  'Documents': [
    {
      'id': 35,
      'documentType': 'BookingConfirmation',
      'fileName': 'confirmation.pdf',
      'uploadedAt': '2026-10-15T18:16:33.588Z',
    },
  ],
};

void main() {
  group('Booking.fromJson', () {
    test('parses every section of a full booking', () {
      final booking = Booking.fromJson(_bookingJson);

      expect(booking.bookingReference, 'TB-PQUZ56');
      expect(booking.customerName, 'Shape Tester');
      expect(booking.totalTravellers, 3);
      expect(booking.travelDate, DateTime(2026, 11, 4));
      expect(booking.flight!.returnFlightNumber, 'LS124');
      expect(booking.flight!.hasReturnFlight, isTrue);
      expect(booking.hotel!.confirmationNumber, 'HC-99812');
      expect(booking.transfer!.transferStatus, 'Confirmed');
      expect(booking.passengers.length, 2);
      expect(booking.passengers.first.passportNumber, isNull);
      expect(booking.documents.single.documentType, 'BookingConfirmation');
    });

    test(
      'works out the remaining balance because bookings do not carry it',
      () {
        final booking = Booking.fromJson(_bookingJson);

        expect(booking.payment!.totalPackagePrice, 2450.0);
        expect(booking.payment!.amountPaid, 1000.0);
        expect(booking.payment!.remainingBalance, 1450.0);
      },
    );

    test('a booking without flight, hotel or payment still parses', () {
      final booking = Booking.fromJson({
        'id': 1,
        'bookingReference': 'TB-AAAAAA',
        'status': 'Pending',
        'destination': 'Dalaman',
        'travelDate': '2026-12-01',
        'returnDate': '2026-12-08',
        'numNights': 7,
        'numAdults': 1,
      });

      expect(booking.flight, isNull);
      expect(booking.hotel, isNull);
      expect(booking.transfer, isNull);
      expect(booking.payment, isNull);
      expect(booking.passengers, isEmpty);
      expect(booking.documents, isEmpty);
    });

    test('passenger initials', () {
      final p = Passenger.fromJson({
        'id': 1,
        'fullName': 'Ahad Ali Khan',
        'passengerType': 'Adult',
      });
      expect(p.initials, 'AK');
    });
  });

  group('payments', () {
    test('history with a refund', () {
      final details = PaymentDetails.fromJson({
        'totalPackagePrice': 2450,
        'amountPaid': 500,
        'remainingBalance': 1950,
        'paymentDueDate': '2026-10-25',
        'paymentStatus': 'PartiallyPaid',
        'history': [
          {
            'id': 1,
            'amount': 1000,
            'paymentDate': '2026-10-15T18:16:33.596Z',
            'method': 'Card',
            'note': 'Deposit',
          },
          {
            'id': 2,
            'amount': -500,
            'paymentDate': '2026-10-16T10:00:00.000Z',
            'method': 'Card',
            'note': 'Refund',
          },
        ],
      });

      expect(details.summary.remainingBalance, 1950.0);
      expect(details.history.length, 2);
      expect(details.history.first.isRefund, isFalse);
      expect(details.history.last.isRefund, isTrue);
    });

    test('overdue only when money is owed and the date has passed', () {
      const owed = PaymentSummary(
        totalPackagePrice: 100,
        amountPaid: 0,
        remainingBalance: 100,
        paymentStatus: 'Unpaid',
      );
      expect(owed.isOverdue, isFalse);

      final overdue = PaymentSummary.fromJson({
        'totalPackagePrice': 100,
        'amountPaid': 0,
        'paymentDueDate': '2020-01-01',
        'paymentStatus': 'Unpaid',
      });
      expect(overdue.isOverdue, isTrue);

      final paid = PaymentSummary.fromJson({
        'totalPackagePrice': 100,
        'amountPaid': 100,
        'paymentDueDate': '2020-01-01',
        'paymentStatus': 'FullyPaid',
      });
      expect(paid.isOverdue, isFalse);
    });
  });

  group('timeline', () {
    int done(String status) =>
        buildTimeline(status).where((s) => s.done).length;

    test('has the seven stages from the specification', () {
      final steps = buildTimeline('Pending');
      expect(steps.length, 7);
      expect(steps.first.label, 'Booking Created');
      expect(steps.last.label, 'Completed');
    });

    test('progress follows the booking status', () {
      expect(done('Pending'), 1);
      expect(done('AwaitingPayment'), 1);
      expect(done('PaymentReceived'), 2);
      expect(done('Confirmed'), 4);
      expect(done('DocumentsPending'), 4);
      expect(done('DocumentsIssued'), 5);
      expect(done('ReadyToTravel'), 6);
      expect(done('TravelCompleted'), 7);
      expect(done('Closed'), 7);
    });

    test('a cancelled booking shows no progress', () {
      expect(done('Cancelled'), 0);
      expect(statusRank('Cancelled'), -1);
    });
  });

  group('formatters', () {
    test(
      'formatDateTimeUtc shows the stored time without converting time zones',
      () {
        expect(
          formatDateTimeUtc(DateTime.utc(2026, 11, 4, 6, 0)),
          'Wed 4 Nov, 06:00',
        );
        expect(formatDateTimeUtc(null), '-');
      },
    );

    test('documentTypeLabel', () {
      expect(documentTypeLabel('BookingConfirmation'), 'Booking Confirmation');
      expect(documentTypeLabel('ATOLCertificate'), 'ATOL Certificate');
      expect(documentTypeLabel('PaymentReceipt'), 'Payment Receipt');
    });

    test('travellersLabel', () {
      expect(travellersLabel(2, 1, 0), '2 adults, 1 child');
      expect(travellersLabel(1, 0, 1), '1 adult, 1 infant');
      expect(travellersLabel(0, 0, 0), '-');
    });

    test('maskSecret keeps only the last four characters', () {
      expect(maskSecret('AB1234567'), '•••••4567');
      expect(maskSecret('123'), '•••');
      expect(maskSecret(null), '-');
      expect(maskSecret(''), '-');
    });
  });
}
