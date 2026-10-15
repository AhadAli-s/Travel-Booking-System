import 'package:flutter/foundation.dart';

/// Where the Node API lives.
///
/// Defaults:
///   Android emulator -> http://10.0.2.2:5000/api  (10.0.2.2 is the emulator's alias for your PC)
///   everything else  -> http://localhost:5000/api
///
/// Override at run time, for example for a real phone on the same Wi-Fi:
///   flutter run --dart-define=API_URL=http://192.168.1.20:5000/api
class AppConfig {
  static const String _override = String.fromEnvironment('API_URL');

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api';
    }
    return 'http://localhost:5000/api';
  }
}
