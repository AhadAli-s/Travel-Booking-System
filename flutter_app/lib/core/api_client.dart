import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error shown to the user. [statusCode] is null when the server could not be reached.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isNetworkError => statusCode == null;

  @override
  String toString() => message;
}

/// Thin wrapper around package:http. It adds the JWT, decodes JSON and turns
/// every failure into an [ApiException] carrying the server's "error" message.
class ApiClient {
  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;
  String? _token;

  /// Called when a request made with a token comes back 401 (expired or revoked session).
  void Function()? onUnauthorized;

  void setToken(String? token) => _token = token;

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send('GET', path, query: query);

  Future<dynamic> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<dynamic> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<dynamic> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<dynamic> delete(String path) => _send('DELETE', path);

  /// Multipart upload for endpoints that take a file (document upload).
  /// [fileField] is the form field name the server expects for the file
  /// (the document endpoints expect "file"); [fields] are the other form fields
  /// (e.g. documentType).
  Future<dynamic> postMultipart(
    String path, {
    required String fileField,
    required List<int> fileBytes,
    required String fileName,
    Map<String, String> fields = const {},
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest('POST', uri);
    if (_token != null) request.headers['Authorization'] = 'Bearer $_token';
    request.fields.addAll(fields);
    request.files.add(
      http.MultipartFile.fromBytes(fileField, fileBytes, filename: fileName),
    );

    http.StreamedResponse streamed;
    try {
      streamed = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (_) {
      throw ApiException(
        'Cannot reach the server. Check your connection and try again.',
      );
    }

    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    var uri = Uri.parse('$baseUrl$path');
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }

    final headers = <String, String>{'Accept': 'application/json'};
    if (body != null) headers['Content-Type'] = 'application/json';
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    final encodedBody = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      final Future<http.Response> request;
      switch (method) {
        case 'POST':
          request = _client.post(uri, headers: headers, body: encodedBody);
          break;
        case 'PUT':
          request = _client.put(uri, headers: headers, body: encodedBody);
          break;
        case 'PATCH':
          request = _client.patch(uri, headers: headers, body: encodedBody);
          break;
        case 'DELETE':
          request = _client.delete(uri, headers: headers);
          break;
        default:
          request = _client.get(uri, headers: headers);
      }
      response = await request.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException(
        'The server took too long to respond. Please try again.',
      );
    } catch (_) {
      throw ApiException(
        'Cannot reach the server. Check your connection and try again.',
      );
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    dynamic data;
    if (response.bodyBytes.isNotEmpty) {
      try {
        data = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = (data is Map && data['error'] is String)
        ? data['error'] as String
        : 'Something went wrong (${response.statusCode}).';

    if (response.statusCode == 401 && _token != null) {
      onUnauthorized?.call();
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
