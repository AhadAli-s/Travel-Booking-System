import '../core/json_utils.dart';
import 'payment.dart';
import 'staff.dart';

List<T> _parseList<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return <T>[];
  return value.whereType<Map<String, dynamic>>().map(parse).toList();
}

class FlightInfo {
  const FlightInfo({
    required this.airline,
    required this.flightNumber,
    required this.departureAirport,
    required this.arrivalAirport,
    this.departureTime,
    this.arrivalTime,
    this.returnFlightNumber,
    this.returnDepartureTime,
    this.returnArrivalTime,
    this.baggageAllowance,
  });

  final String airline;
  final String flightNumber;
  final String departureAirport;
  final String arrivalAirport;
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final String? returnFlightNumber;
  final DateTime? returnDepartureTime;
  final DateTime? returnArrivalTime;
  final String? baggageAllowance;

  bool get hasReturnFlight =>
      (returnFlightNumber != null && returnFlightNumber!.isNotEmpty) ||
      returnDepartureTime != null ||
      returnArrivalTime != null;

  factory FlightInfo.fromJson(Map<String, dynamic> json) {
    return FlightInfo(
      airline: (json['airline'] ?? '').toString(),
      flightNumber: (json['flightNumber'] ?? '').toString(),
      departureAirport: (json['departureAirport'] ?? '').toString(),
      arrivalAirport: (json['arrivalAirport'] ?? '').toString(),
      departureTime: parseDate(json['departureTime']),
      arrivalTime: parseDate(json['arrivalTime']),
      returnFlightNumber: toNullableString(json['returnFlightNumber']),
      returnDepartureTime: parseDate(json['returnDepartureTime']),
      returnArrivalTime: parseDate(json['returnArrivalTime']),
      baggageAllowance: toNullableString(json['baggageAllowance']),
    );
  }
}

class HotelInfo {
  const HotelInfo({
    required this.hotelName,
    required this.numRooms,
    this.hotelAddress,
    this.roomType,
    this.boardBasis,
    this.checkInDate,
    this.checkOutDate,
    this.confirmationNumber,
  });

  final String hotelName;
  final String? hotelAddress;
  final String? roomType;
  final int numRooms;
  final String? boardBasis;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? confirmationNumber;

  factory HotelInfo.fromJson(Map<String, dynamic> json) {
    return HotelInfo(
      hotelName: (json['hotelName'] ?? '').toString(),
      hotelAddress: toNullableString(json['hotelAddress']),
      roomType: toNullableString(json['roomType']),
      numRooms: toInt(json['numRooms']),
      boardBasis: toNullableString(json['boardBasis']),
      checkInDate: parseDate(json['checkInDate']),
      checkOutDate: parseDate(json['checkOutDate']),
      confirmationNumber: toNullableString(json['confirmationNumber']),
    );
  }
}

class TransferInfo {
  const TransferInfo({
    required this.transferStatus,
    this.pickupLocation,
    this.pickupTime,
    this.dropoffLocation,
  });

  final String? pickupLocation;
  final DateTime? pickupTime;
  final String? dropoffLocation;
  final String transferStatus;

  factory TransferInfo.fromJson(Map<String, dynamic> json) {
    return TransferInfo(
      pickupLocation: toNullableString(json['pickupLocation']),
      pickupTime: parseDate(json['pickupTime']),
      dropoffLocation: toNullableString(json['dropoffLocation']),
      transferStatus: (json['transferStatus'] ?? '').toString(),
    );
  }
}

class Passenger {
  const Passenger({
    required this.id,
    required this.fullName,
    required this.passengerType,
    this.dateOfBirth,
    this.passportNumber,
    this.passportExpiry,
    this.specialAssistance,
    this.mealPreference,
    this.baggage,
  });

  final int id;
  final String fullName;
  final DateTime? dateOfBirth;
  final String passengerType;

  /// Only present on the detail endpoint. List and booking views never include it.
  final String? passportNumber;
  final DateTime? passportExpiry;
  final String? specialAssistance;
  final String? mealPreference;
  final String? baggage;

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      id: toInt(json['id']),
      fullName: (json['fullName'] ?? '').toString(),
      dateOfBirth: parseDate(json['dateOfBirth']),
      passengerType: (json['passengerType'] ?? '').toString(),
      passportNumber: toNullableString(json['passportNumber']),
      passportExpiry: parseDate(json['passportExpiry']),
      specialAssistance: toNullableString(json['specialAssistance']),
      mealPreference: toNullableString(json['mealPreference']),
      baggage: toNullableString(json['baggage']),
    );
  }

  static List<Passenger> listFromJson(dynamic value) =>
      _parseList(value, Passenger.fromJson);

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class TravelDocument {
  const TravelDocument({
    required this.id,
    required this.documentType,
    required this.fileName,
    this.uploadedAt,
  });

  final int id;
  final String documentType;
  final String fileName;
  final DateTime? uploadedAt;

  factory TravelDocument.fromJson(Map<String, dynamic> json) {
    return TravelDocument(
      id: toInt(json['id']),
      documentType: (json['documentType'] ?? '').toString(),
      fileName: (json['fileName'] ?? '').toString(),
      uploadedAt: parseDate(json['uploadedAt']),
    );
  }

  static List<TravelDocument> listFromJson(dynamic value) =>
      _parseList(value, TravelDocument.fromJson);
}

class Booking {
  const Booking({
    required this.id,
    required this.bookingReference,
    required this.status,
    required this.destination,
    required this.numAdults,
    required this.numChildren,
    required this.numInfants,
    required this.numNights,
    this.bookingDate,
    this.departureCity,
    this.departureAirport,
    this.travelDate,
    this.returnDate,
    this.notes,
    this.customerId,
    this.customerName,
    this.customerEmail,
    this.assignedStaff,
    this.flight,
    this.hotel,
    this.transfer,
    this.payment,
    this.passengers = const <Passenger>[],
    this.documents = const <TravelDocument>[],
  });

  final int id;
  final String bookingReference;
  final DateTime? bookingDate;
  final String status;
  final String destination;
  final String? departureCity;
  final String? departureAirport;
  final DateTime? travelDate;
  final DateTime? returnDate;
  final int numNights;
  final int numAdults;
  final int numChildren;
  final int numInfants;
  final String? notes;

  /// Only present when a staff member fetched this booking (GET /bookings or /bookings/:id for staff).
  final int? customerId;
  final String? customerName;
  final String? customerEmail;

  /// Staff this booking is assigned to, or null if unassigned. Staff only.
  final Staff? assignedStaff;

  final FlightInfo? flight;
  final HotelInfo? hotel;
  final TransferInfo? transfer;
  final PaymentSummary? payment;
  final List<Passenger> passengers;
  final List<TravelDocument> documents;

  int get totalTravellers => numAdults + numChildren + numInfants;

  bool get isCancelled => status == 'Cancelled';

  /// Whole days from today until departure, or null when the date is unknown.
  int? get daysUntilTravel {
    final travel = travelDate;
    if (travel == null) return null;
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return DateTime.utc(
      travel.year,
      travel.month,
      travel.day,
    ).difference(today).inDays;
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    final flight = json['Flight'];
    final hotel = json['Hotel'];
    final transfer = json['Transfer'];
    final payment = json['Payment'];
    final customer = json['Customer'];
    final assignedStaff = json['assignedStaff'];
    return Booking(
      id: toInt(json['id']),
      bookingReference: (json['bookingReference'] ?? '').toString(),
      bookingDate: parseDate(json['bookingDate']),
      status: (json['status'] ?? '').toString(),
      destination: (json['destination'] ?? '').toString(),
      departureCity: toNullableString(json['departureCity']),
      departureAirport: toNullableString(json['departureAirport']),
      travelDate: parseDate(json['travelDate']),
      returnDate: parseDate(json['returnDate']),
      numNights: toInt(json['numNights']),
      numAdults: toInt(json['numAdults']),
      numChildren: toInt(json['numChildren']),
      numInfants: toInt(json['numInfants']),
      notes: toNullableString(json['notes']),
      customerId: json['customerId'] == null ? null : toInt(json['customerId']),
      customerName: customer is Map<String, dynamic>
          ? toNullableString(customer['fullName'])
          : null,
      customerEmail: customer is Map<String, dynamic>
          ? toNullableString(customer['email'])
          : null,
      assignedStaff: assignedStaff is Map<String, dynamic>
          ? Staff.fromJson(assignedStaff)
          : null,
      flight: flight is Map<String, dynamic>
          ? FlightInfo.fromJson(flight)
          : null,
      hotel: hotel is Map<String, dynamic> ? HotelInfo.fromJson(hotel) : null,
      transfer: transfer is Map<String, dynamic>
          ? TransferInfo.fromJson(transfer)
          : null,
      payment: payment is Map<String, dynamic>
          ? PaymentSummary.fromJson(payment)
          : null,
      passengers: Passenger.listFromJson(json['Passengers']),
      documents: TravelDocument.listFromJson(json['Documents']),
    );
  }

  static List<Booking> listFromJson(dynamic value) =>
      _parseList(value, Booking.fromJson);
}

/// Result of GET /bookings/my.
class BookingsOverview {
  const BookingsOverview({
    required this.upcoming,
    required this.active,
    required this.previous,
  });

  final List<Booking> upcoming;
  final List<Booking> active;
  final List<Booking> previous;

  factory BookingsOverview.fromJson(Map<String, dynamic> json) {
    return BookingsOverview(
      upcoming: Booking.listFromJson(json['upcoming']),
      active: Booking.listFromJson(json['active']),
      previous: Booking.listFromJson(json['previous']),
    );
  }
}
