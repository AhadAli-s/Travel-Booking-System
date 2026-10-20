import 'package:flutter_test/flutter_test.dart';
import 'package:travel_booking_app/core/ticket_meta.dart';
import 'package:travel_booking_app/models/app_notification.dart';
import 'package:travel_booking_app/models/ticket.dart';

/// Shapes taken from real API responses (POST /tickets, GET /tickets/:id, GET /notifications).
void main() {
  group('SupportTicket.fromJson', () {
    test('parses a ticket with no replies', () {
      final ticket = SupportTicket.fromJson({
        'id': 100,
        'customerId': 133,
        'bookingId': 133,
        'category': 'Payment',
        'subject': 'Question about deposit',
        'description': 'When is my deposit due exactly?',
        'status': 'Open',
        'updatedAt': '2026-10-18T08:55:32.679Z',
        'createdAt': '2026-10-18T08:55:32.679Z',
        'assignedStaffId': null,
      });

      expect(ticket.subject, 'Question about deposit');
      expect(ticket.bookingId, 133);
      expect(ticket.status, 'Open');
      expect(ticket.isClosed, isFalse);
      expect(ticket.replies, isEmpty);
    });

    test('parses a ticket detail with its reply thread', () {
      final ticket = SupportTicket.fromJson({
        'id': 100,
        'category': 'Payment',
        'subject': 'Question about deposit',
        'description': 'When is my deposit due exactly?',
        'status': 'WaitingForCustomer',
        'createdAt': '2026-10-18T08:55:32.679Z',
        'updatedAt': '2026-10-18T08:55:32.713Z',
        'bookingId': 133,
        'replies': [
          {
            'id': 100,
            'senderType': 'Staff',
            'message': 'Your deposit is due 10 Nov 2026.',
            'createdAt': '2026-10-18T08:55:32.710Z',
          },
        ],
      });

      expect(ticket.replies.length, 1);
      expect(ticket.replies.single.fromStaff, isTrue);
      expect(ticket.replies.single.message, 'Your deposit is due 10 Nov 2026.');
    });

    test('a general support ticket has no bookingId', () {
      final ticket = SupportTicket.fromJson({
        'id': 1,
        'category': 'GeneralSupport',
        'subject': 'App question',
        'description': 'How do I change my email?',
        'status': 'Open',
      });

      expect(ticket.bookingId, isNull);
    });
  });

  group('AppNotification.fromJson', () {
    test('parses the list shape from GET /notifications', () {
      final notifications = AppNotification.listFromJson([
        {
          'id': 101,
          'type': 'TicketResolved',
          'message': 'Your ticket "Question about deposit" has been marked as resolved.',
          'isRead': false,
          'createdAt': '2026-10-18T08:55:32.780Z',
        },
      ]);

      expect(notifications.single.type, 'TicketResolved');
      expect(notifications.single.isRead, isFalse);
    });

    test('isRead only true when the server sends exactly true', () {
      final read = AppNotification.fromJson({
        'id': 1,
        'type': 'X',
        'message': 'm',
        'isRead': true,
      });
      final unread = AppNotification.fromJson({
        'id': 2,
        'type': 'X',
        'message': 'm',
        'isRead': false,
      });
      expect(read.isRead, isTrue);
      expect(unread.isRead, isFalse);
    });
  });

  group('ticket category helpers', () {
    test('every category in the list has a label', () {
      for (final category in ticketCategories) {
        expect(ticketCategoryLabel(category), isNotEmpty);
      }
    });

    test('camelCase categories are split into words', () {
      expect(ticketCategoryLabel('PassengerDetails'), 'Passenger Details');
      expect(
        ticketCategoryLabel('CancellationRequest'),
        'Cancellation Request',
      );
      expect(ticketCategoryLabel('GeneralSupport'), 'General Support');
      expect(ticketCategoryLabel('Flight'), 'Flight');
    });

    test('status list matches the backend enum', () {
      expect(ticketStatuses, [
        'Open',
        'InProgress',
        'WaitingForCustomer',
        'Resolved',
        'Closed',
      ]);
    });
  });
}
