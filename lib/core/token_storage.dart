import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the JWT between app launches so the customer stays signed in.
/// The server enforces expiry (7 days for customers) and the token is
/// deleted on logout or when the server answers 401.
class TokenStorage {
  static const String _key = 'auth_token';

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
