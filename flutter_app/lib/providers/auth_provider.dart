import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/customer.dart';

enum AuthStatus { unknown, signedOut, signedIn }

/// Owns the signed in customer and the session token.
class AuthProvider extends ChangeNotifier {
  // The constructor takes public named arguments (api, storage) and stores them
  // in private fields, so an initializing formal (this._api) is not possible here.
  AuthProvider({required ApiClient api, required TokenStorage storage})
    : _api = api, // ignore: prefer_initializing_formals
      _storage = storage {// ignore: prefer_initializing_formals
    _api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient _api;
  final TokenStorage _storage;

  AuthStatus _status = AuthStatus.unknown;
  Customer? _customer;
  bool _minimumSplashDone = false;

  AuthStatus get status => _status;
  Customer? get customer => _customer;

  /// True while the splash screen should stay visible.
  bool get showSplash => !_minimumSplashDone || _status == AuthStatus.unknown;

  /// Called once at start up. Restores a saved session and keeps the splash for at least 1.5 seconds.
  Future<void> boot() async {
    final minimumSplash = Future<void>.delayed(
      const Duration(milliseconds: 1500),
    );
    await _restoreSession();
    await minimumSplash;
    _minimumSplashDone = true;
    notifyListeners();
  }

  Future<void> _restoreSession() async {
    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.signedOut;
      return;
    }
    _api.setToken(token);
    try {
      final json = await _api.get('/profile');
      _customer = Customer.fromJson(json as Map<String, dynamic>);
      _status = AuthStatus.signedIn;
    } catch (_) {
      // A 401 already cleared the session through onUnauthorized. Any other
      // failure (server offline, unexpected response) shows the login screen.
      _api.setToken(null);
      _status = AuthStatus.signedOut;
    }
  }

  Future<void> login(String email, String password) async {
    final json = await _api.post(
      '/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
    await _completeSignIn(json as Map<String, dynamic>);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': email.trim(),
      'password': password,
    };
    if (phone != null && phone.trim().isNotEmpty) body['phone'] = phone.trim();
    final json = await _api.post('/auth/register', body: body);
    await _completeSignIn(json as Map<String, dynamic>);
  }

  /// Returns the reset code when the server runs outside production (development helper).
  /// In production the code is emailed and this returns null.
  Future<String?> requestPasswordReset(String email) async {
    final json = await _api.post(
      '/auth/forgot-password',
      body: {'email': email.trim()},
    );
    if (json is Map<String, dynamic>) {
      final token = json['devResetToken'];
      if (token is String && token.isNotEmpty) return token;
    }
    return null;
  }

  Future<void> resetPassword(String resetToken, String newPassword) async {
    await _api.post(
      '/auth/reset-password',
      body: {'resetToken': resetToken.trim(), 'newPassword': newPassword},
    );
  }

  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Signing out locally is enough when the server cannot be reached.
    }
    await _clearSession();
  }

  Future<void> _completeSignIn(Map<String, dynamic> json) async {
    final token = json['token'] as String;
    await _storage.write(token);
    _api.setToken(token);
    _customer = Customer.fromJson(json['customer'] as Map<String, dynamic>);
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  void _handleUnauthorized() {
    _clearSession();
  }

  Future<void> _clearSession() async {
    _api.setToken(null);
    await _storage.clear();
    _customer = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }
}
