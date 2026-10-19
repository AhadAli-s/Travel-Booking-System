import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/staff.dart';

enum StaffAuthStatus { signedOut, signedIn }

/// Owns the signed in staff member and their session token.
/// Kept entirely separate from AuthProvider (customers): a device can be
/// signed in as a customer and as staff at the same time with two tokens.
class StaffAuthProvider extends ChangeNotifier {
  // The constructor takes public named arguments (api, storage) and stores them
  // in private fields, so an initializing formal (this._api) is not possible here.
  StaffAuthProvider({required ApiClient api, required TokenStorage storage})
    : _api = api, // ignore: prefer_initializing_formals
      _storage = storage; // ignore: prefer_initializing_formals

  final ApiClient _api;
  final TokenStorage _storage;

  StaffAuthStatus _status = StaffAuthStatus.signedOut;
  Staff? _staff;

  StaffAuthStatus get status => _status;
  Staff? get staff => _staff;

  Future<void> login(String email, String password) async {
    final json = await _api.post(
      '/auth/staff/login',
      body: {'email': email.trim(), 'password': password},
    ) as Map<String, dynamic>;

    final token = json['token'] as String;
    await _storage.write(token);
    _api.setToken(token);
    _staff = Staff.fromJson(json['staff'] as Map<String, dynamic>);
    _status = StaffAuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> logout() async {
    _api.setToken(null);
    await _storage.clear();
    _staff = null;
    _status = StaffAuthStatus.signedOut;
    notifyListeners();
  }
}
