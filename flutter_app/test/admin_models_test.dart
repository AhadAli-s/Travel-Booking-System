import 'package:flutter_test/flutter_test.dart';
import 'package:travel_booking_app/core/admin_meta.dart';
import 'package:travel_booking_app/models/admin_customer.dart';
import 'package:travel_booking_app/models/booking.dart';
import 'package:travel_booking_app/models/staff.dart';

/// Shapes taken from real GET /bookings (staff), GET /admin/customers,
/// GET /admin/customers/:id and GET /admin/staff responses.
void main() {
  group('Booking.fromJson (staff view)', () {
    test('parses customerId, customerEmail and assignedStaff', () {
      final booking = Booking.fromJson({
        'id': 133,
        'bookingReference': 'TB-C6UKQS',
        'status': 'Confirmed',
        'destination': 'Antalya, Turkey',
        'numAdults': 2,
        'numChildren': 0,
        'numInfants': 0,
        'numNights': 7,
        'travelDate': '2026-11-04',
        'returnDate': '2026-11-11',
        'customerId': 61,
        'Customer': {
          'id': 61,
          'fullName': 'Fill Test',
          'email': 'fill.test2@example.com',
        },
        'assignedStaff': {
          'id': 2,
          'fullName': 'Agent Smith',
          'role': 'BookingAgent',
        },
      });

      expect(booking.customerId, 61);
      expect(booking.customerEmail, 'fill.test2@example.com');
      expect(booking.assignedStaff!.fullName, 'Agent Smith');
      expect(booking.assignedStaff!.role, 'BookingAgent');
    });

    test('assignedStaff is null when unassigned', () {
      final booking = Booking.fromJson({
        'id': 1,
        'bookingReference': 'TB-AAAAAA',
        'status': 'Pending',
        'destination': 'Dalaman',
        'numAdults': 1,
        'numChildren': 0,
        'numInfants': 0,
        'numNights': 7,
        'assignedStaff': null,
      });
      expect(booking.assignedStaff, isNull);
    });
  });

  group('Staff.fromJson', () {
    test('parses the full admin staff list shape (with status)', () {
      final staff = Staff.listFromJson([
        {
          'id': 1,
          'fullName': 'Admin User',
          'email': 'admin@travelagency.com',
          'role': 'Administrator',
          'status': 'Active',
          'createdAt': '2026-09-01T10:00:00.000Z',
        },
      ]);
      expect(staff.single.isActive, isTrue);
      expect(staff.single.role, 'Administrator');
    });

    test('parses the staff login shape (no status field)', () {
      final staff = Staff.fromJson({
        'id': 1,
        'fullName': 'Admin User',
        'email': 'admin@travelagency.com',
        'role': 'Administrator',
      });
      // No status field means isActive defaults to true rather than being
      // treated as inactive, matching a freshly logged in session.
      expect(staff.isActive, isTrue);
      expect(staff.status, isNull);
    });

    test('isActive is false only when status is explicitly Inactive', () {
      final staff = Staff.fromJson({
        'id': 1,
        'fullName': 'X',
        'email': 'x@y.com',
        'role': 'SupportAgent',
        'status': 'Inactive',
      });
      expect(staff.isActive, isFalse);
    });
  });

  group('AdminCustomerDetail.fromJson', () {
    test('parses customer, bookings, tickets and contact history together', () {
      final detail = AdminCustomerDetail.fromJson({
        'customer': {
          'id': 61,
          'fullName': 'Fill Test',
          'email': 'fill.test2@example.com',
          'phone': null,
          'createdAt': '2026-10-15T18:16:33.386Z',
          'totalBookings': 1,
          'activeBookings': 1,
        },
        'bookings': [
          {
            'id': 133,
            'bookingReference': 'TB-C6UKQS',
            'status': 'Confirmed',
            'destination': 'Antalya, Turkey',
            'numAdults': 2,
            'numChildren': 0,
            'numInfants': 0,
            'numNights': 7,
          },
        ],
        'tickets': [],
        'contactHistory': [
          {
            'id': 1,
            'channel': 'Phone',
            'note': 'Called about transfer',
            'bookingId': 133,
            'createdAt': '2026-10-15T18:20:00.000Z',
            'author': {
              'id': 2,
              'fullName': 'Agent Smith',
              'role': 'BookingAgent',
            },
          },
        ],
      });

      expect(detail.customer.fullName, 'Fill Test');
      expect(detail.customer.totalBookings, 1);
      expect(detail.bookings.single.bookingReference, 'TB-C6UKQS');
      expect(detail.tickets, isEmpty);
      expect(detail.contactHistory.single.author!.fullName, 'Agent Smith');
      expect(detail.contactHistory.single.channel, 'Phone');
    });
  });

  group('admin_meta role checks', () {
    test('only Administrator and BookingAgent can edit bookings', () {
      expect(roleCanEditBookings('Administrator'), isTrue);
      expect(roleCanEditBookings('BookingAgent'), isTrue);
      expect(roleCanEditBookings('AccountsStaff'), isFalse);
      expect(roleCanEditBookings('SupportAgent'), isFalse);
    });

    test('only Administrator and AccountsStaff can manage payments', () {
      expect(roleCanManagePayments('AccountsStaff'), isTrue);
      expect(roleCanManagePayments('BookingAgent'), isFalse);
    });

    test('only Administrator and SupportAgent can manage tickets', () {
      expect(roleCanManageTickets('SupportAgent'), isTrue);
      expect(roleCanManageTickets('AccountsStaff'), isFalse);
    });

    test('only Administrator can manage staff', () {
      expect(roleCanManageStaff('Administrator'), isTrue);
      expect(roleCanManageStaff('BookingAgent'), isFalse);
      expect(roleCanManageStaff('AccountsStaff'), isFalse);
      expect(roleCanManageStaff('SupportAgent'), isFalse);
    });

    test('documents can be managed by Administrator, BookingAgent and AccountsStaff', () {
      expect(roleCanManageDocuments('Administrator'), isTrue);
      expect(roleCanManageDocuments('BookingAgent'), isTrue);
      expect(roleCanManageDocuments('AccountsStaff'), isTrue);
      expect(roleCanManageDocuments('SupportAgent'), isFalse);
    });

    test('status and document type lists match the backend enums exactly', () {
      expect(bookingStatuses.length, 11);
      expect(bookingStatuses.first, 'Pending');
      expect(bookingStatuses.last, 'Closed');
      expect(documentTypes.length, 9);
      expect(staffRoles, [
        'Administrator',
        'BookingAgent',
        'AccountsStaff',
        'SupportAgent',
      ]);
    });
  });
}
