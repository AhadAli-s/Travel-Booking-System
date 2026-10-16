import '../core/api_client.dart';
import '../models/booking.dart';
import '../models/payment.dart';

/// All booking related API calls for the customer app.
class BookingService {
  BookingService(this._api);

  final ApiClient _api;

  Future<BookingsOverview> myBookings() async {
    final json = await _api.get('/bookings/my');
    return BookingsOverview.fromJson(json as Map<String, dynamic>);
  }

  Future<Booking> getBooking(int id) async {
    final json = await _api.get('/bookings/$id');
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  /// Public lookup with booking reference and email. No login needed.
  Future<Booking> lookup(String reference, String email) async {
    final json = await _api.post(
      '/bookings/lookup',
      body: {'bookingReference': reference.trim(), 'email': email.trim()},
    );
    return Booking.fromJson(json as Map<String, dynamic>);
  }

  Future<PaymentDetails> getPayment(int bookingId) async {
    final json = await _api.get('/bookings/$bookingId/payment');
    return PaymentDetails.fromJson(json as Map<String, dynamic>);
  }

  Future<Receipt> getReceipt(int bookingId, int receiptId) async {
    final json = await _api.get(
      '/bookings/$bookingId/payment/receipts/$receiptId',
    );
    return Receipt.fromJson(json as Map<String, dynamic>);
  }

  Future<List<TravelDocument>> documents(int bookingId) async {
    final json = await _api.get('/bookings/$bookingId/documents');
    return TravelDocument.listFromJson(json);
  }

  Future<List<Passenger>> passengers(int bookingId) async {
    final json = await _api.get('/bookings/$bookingId/passengers');
    return Passenger.listFromJson(json);
  }

  /// Includes the passport number, so only call it when the customer asks for details.
  Future<Passenger> passengerDetail(int bookingId, int passengerId) async {
    final json = await _api.get('/bookings/$bookingId/passengers/$passengerId');
    return Passenger.fromJson(json as Map<String, dynamic>);
  }

  /// Asks the server for a 90 second signed link to one document.
  Future<Uri> documentLink(int documentId) async {
    final json =
        await _api.get('/documents/$documentId/link') as Map<String, dynamic>;
    final relative = json['url'] as String;
    return Uri.parse(_api.baseUrl).resolve(relative);
  }
}
