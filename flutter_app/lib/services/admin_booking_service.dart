import '../core/api_client.dart';
import '../models/booking.dart';

/// Booking actions available to staff (any role can read; see admin_meta.dart
/// for which roles can perform which write).
class AdminBookingService {
  AdminBookingService(this._api);

  final ApiClient _api;

  /// All bookings, optionally filtered by status. The server returns every
  /// booking in one call (no pagination), so filtering further by search text
  /// is done client-side in the screen.
  Future<List<Booking>> list({String? status}) async {
    final json = await _api.get(
      '/bookings',
      query: status == null ? null : {'status': status},
    );
    return Booking.listFromJson(json);
  }

  Future<Booking> getBooking(int id) async {
    final json = await _api.get('/bookings/$id');
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  /// Edits destination, dates, traveller counts and notes. Status and
  /// customerId are never accepted here, matching the server's whitelist.
  Future<Booking> updateDetails(
    int id, {
    String? destination,
    String? departureCity,
    String? departureAirport,
    String? travelDate,
    String? returnDate,
    int? numAdults,
    int? numChildren,
    int? numInfants,
    String? notes,
  }) async {
    final body = <String, dynamic>{};
    if (destination != null) body['destination'] = destination;
    if (departureCity != null) body['departureCity'] = departureCity;
    if (departureAirport != null) body['departureAirport'] = departureAirport;
    if (travelDate != null) body['travelDate'] = travelDate;
    if (returnDate != null) body['returnDate'] = returnDate;
    if (numAdults != null) body['numAdults'] = numAdults;
    if (numChildren != null) body['numChildren'] = numChildren;
    if (numInfants != null) body['numInfants'] = numInfants;
    if (notes != null) body['notes'] = notes;
    final json = await _api.patch('/bookings/$id', body: body);
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  Future<void> updateStatus(int id, String status) =>
      _api.patch('/bookings/$id/status', body: {'status': status});

  /// Pass null to unassign.
  Future<void> assignStaff(int id, int? staffId) =>
      _api.patch('/bookings/$id/assign', body: {'staffId': staffId});

  Future<FlightInfo> saveFlight(
    int bookingId, {
    required String airline,
    required String flightNumber,
    required String departureAirport,
    required String arrivalAirport,
    required String departureTime,
    required String arrivalTime,
    String? returnFlightNumber,
    String? returnDepartureTime,
    String? returnArrivalTime,
    String? baggageAllowance,
  }) async {
    final json = await _api.put(
      '/bookings/$bookingId/flight',
      body: {
        'airline': airline,
        'flightNumber': flightNumber,
        'departureAirport': departureAirport,
        'arrivalAirport': arrivalAirport,
        'departureTime': departureTime,
        'arrivalTime': arrivalTime,
        if (returnFlightNumber != null)
          'returnFlightNumber': returnFlightNumber,
        if (returnDepartureTime != null)
          'returnDepartureTime': returnDepartureTime,
        if (returnArrivalTime != null) 'returnArrivalTime': returnArrivalTime,
        if (baggageAllowance != null) 'baggageAllowance': baggageAllowance,
      },
    );
    return FlightInfo.fromJson(json as Map<String, dynamic>);
  }

  Future<HotelInfo> saveHotel(
    int bookingId, {
    required String hotelName,
    required String checkInDate,
    required String checkOutDate,
    String? hotelAddress,
    String? roomType,
    int? numRooms,
    String? boardBasis,
    String? confirmationNumber,
  }) async {
    final json = await _api.put(
      '/bookings/$bookingId/hotel',
      body: {
        'hotelName': hotelName,
        'checkInDate': checkInDate,
        'checkOutDate': checkOutDate,
        if (hotelAddress != null) 'hotelAddress': hotelAddress,
        if (roomType != null) 'roomType': roomType,
        if (numRooms != null) 'numRooms': numRooms,
        if (boardBasis != null) 'boardBasis': boardBasis,
        if (confirmationNumber != null)
          'confirmationNumber': confirmationNumber,
      },
    );
    return HotelInfo.fromJson(json as Map<String, dynamic>);
  }

  Future<TransferInfo> saveTransfer(
    int bookingId, {
    String? pickupLocation,
    String? pickupTime,
    String? dropoffLocation,
    String? transferStatus,
  }) async {
    final json = await _api.put(
      '/bookings/$bookingId/transfer',
      body: {
        if (pickupLocation != null) 'pickupLocation': pickupLocation,
        if (pickupTime != null) 'pickupTime': pickupTime,
        if (dropoffLocation != null) 'dropoffLocation': dropoffLocation,
        if (transferStatus != null) 'transferStatus': transferStatus,
      },
    );
    return TransferInfo.fromJson(json as Map<String, dynamic>);
  }

  /// Returns the new amountPaid and paymentStatus (not the full payment summary).
  Future<Map<String, dynamic>> recordPayment(
    int bookingId, {
    required double amount,
    String? method,
    String? note,
  }) async {
    final json = await _api.post(
      '/bookings/$bookingId/payment',
      body: {
        'amount': amount,
        if (method != null) 'method': method,
        if (note != null) 'note': note,
      },
    );
    return json as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> issueRefund(
    int bookingId, {
    required double amount,
    String? note,
  }) async {
    final json = await _api.post(
      '/bookings/$bookingId/payment/refund',
      body: {'amount': amount, if (note != null) 'note': note},
    );
    return json as Map<String, dynamic>;
  }
}
