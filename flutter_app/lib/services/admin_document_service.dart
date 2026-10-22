import 'dart:typed_data';

import '../core/api_client.dart';
import '../models/booking.dart';

class AdminDocumentService {
  AdminDocumentService(this._api);

  final ApiClient _api;

  Future<TravelDocument> upload({
    required int bookingId,
    required String documentType,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final json = await _api.postMultipart(
      '/bookings/$bookingId/documents',
      fileField: 'file',
      fileBytes: bytes,
      fileName: fileName,
      fields: {'documentType': documentType},
    );
    return TravelDocument.fromJson(json as Map<String, dynamic>);
  }

  Future<void> delete(int documentId) => _api.delete('/documents/$documentId');
}
