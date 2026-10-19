import 'package:shared_preferences/shared_preferences.dart';

/// Keeps a JWT between app launches so the person stays signed in.
/// The server enforces expiry (7 days for customers, 12 hours for staff) and
/// the token is deleted on logout or when the server answers 401.
///
/// Pass a distinct [storageKey] per session type: customer and staff tokens
/// must not share a key, or signing in as one would overwrite the other's
/// saved session on disk even though their in-memory ApiClients stay separate.
class TokenStorage {
  TokenStorage({this.storageKey = 'auth_token'});

  final String storageKey;

  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(storageKey);
  }

  Future<void> write(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(storageKey, token);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
