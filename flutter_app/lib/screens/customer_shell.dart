import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'customer_dashboard_screen.dart';
import 'my_bookings_screen.dart';

/// Signed in home: bottom navigation between the customer's main pages.
class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key});

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [CustomerDashboardScreen(), MyBookingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        indicatorColor: AppColors.pinkTint,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.pink),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.luggage_outlined),
            selectedIcon: Icon(Icons.luggage, color: AppColors.pink),
            label: 'My bookings',
          ),
        ],
      ),
    );
  }
}
