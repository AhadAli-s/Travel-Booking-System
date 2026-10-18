import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'core/token_storage.dart';
import 'providers/auth_provider.dart';
import 'screens/customer_shell.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';

class TravelBookingApp extends StatefulWidget {
  const TravelBookingApp({super.key});

  @override
  State<TravelBookingApp> createState() => _TravelBookingAppState();
}

class _TravelBookingAppState extends State<TravelBookingApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ApiClient _api;
  late final AuthProvider _auth;
  AuthStatus _lastStatus = AuthStatus.unknown;

  @override
  void initState() {
    super.initState();
    _api = ApiClient(baseUrl: AppConfig.apiBaseUrl);
    _auth = AuthProvider(api: _api, storage: TokenStorage());
    _auth.addListener(_onAuthChanged);
    _auth.boot();
  }

  /// When the session ends (logout or expired token) close any pages that are
  /// open on top of the home screen so the login screen is what the user sees.
  void _onAuthChanged() {
    if (_auth.status == AuthStatus.signedOut &&
        _lastStatus == AuthStatus.signedIn) {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    _lastStatus = _auth.status;
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: _api),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
      ],
      child: MaterialApp(
        title: 'Manage My Booking',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: AppTheme.light,
        home: const _AuthGate(),
      ),
    );
  }
}

/// Chooses the home screen from the session state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.showSplash) {
      return const SplashScreen();
    }
    if (auth.status == AuthStatus.signedIn) {
      return const CustomerShell();
    }
    return const LoginScreen();
  }
}
