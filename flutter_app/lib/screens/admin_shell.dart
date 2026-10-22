import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/admin_meta.dart';
import '../core/theme.dart';
import '../providers/staff_auth_provider.dart';
import 'admin_bookings_screen.dart';
import 'admin_customers_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_staff_screen.dart';
import 'admin_tickets_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon, this.content);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget content;
}

/// Staff home: one Scaffold for the whole admin area, with a side rail on wide
/// screens (desktop, web, tablet landscape) or a drawer on narrow screens
/// (phone), since staff typically run this continuously on a larger screen
/// rather than checking it like a phone app. A Drawer and its hamburger icon
/// must share one Scaffold, which is why each tab below is plain content with
/// no Scaffold of its own, and this shell owns the single AppBar and sign out
/// action for all of them. Staff Management only appears for Administrators;
/// the server also enforces this on every request.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You will need to sign in again to access the staff portal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<StaffAuthProvider>().logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffAuthProvider>().staff;
    final role = staff?.role ?? '';

    final destinations = <_Destination>[
      const _Destination(
        'Dashboard',
        Icons.dashboard_outlined,
        Icons.dashboard,
        AdminDashboardScreen(),
      ),
      const _Destination(
        'Customers',
        Icons.people_outline,
        Icons.people,
        AdminCustomersScreen(),
      ),
      const _Destination(
        'Bookings',
        Icons.luggage_outlined,
        Icons.luggage,
        AdminBookingsScreen(),
      ),
      const _Destination(
        'Tickets',
        Icons.support_agent_outlined,
        Icons.support_agent,
        AdminTicketsScreen(),
      ),
      if (roleCanManageStaff(role))
        const _Destination(
          'Staff',
          Icons.badge_outlined,
          Icons.badge,
          AdminStaffScreen(),
        ),
    ];
    final index = _index < destinations.length ? _index : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;

        return Scaffold(
          backgroundColor: const Color(0xFFFAFAFB),
          drawer: wide
              ? null
              : Drawer(
                  child: SafeArea(
                    child: ListView(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flight_takeoff,
                                color: AppColors.pink,
                                size: 28,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Agency portal',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (int i = 0; i < destinations.length; i++)
                          ListTile(
                            leading: Icon(
                              i == index
                                  ? destinations[i].selectedIcon
                                  : destinations[i].icon,
                              color: i == index
                                  ? AppColors.pink
                                  : AppColors.muted,
                            ),
                            title: Text(
                              destinations[i].label,
                              style: TextStyle(
                                color: i == index
                                    ? AppColors.pink
                                    : AppColors.ink,
                                fontWeight: i == index
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: i == index,
                            selectedTileColor: AppColors.pinkTint,
                            onTap: () {
                              setState(() => _index = i);
                              Navigator.of(context).pop();
                            },
                          ),
                      ],
                    ),
                  ),
                ),
          appBar: AppBar(
            backgroundColor: AppColors.pink,
            foregroundColor: Colors.white,
            title: Text(
              destinations[index].label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            actions: [
              IconButton(
                tooltip: 'Sign out',
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Row(
            children: [
              if (wide) ...[
                NavigationRail(
                  selectedIndex: index,
                  onDestinationSelected: (value) =>
                      setState(() => _index = value),
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.white,
                  selectedIconTheme: const IconThemeData(color: AppColors.pink),
                  selectedLabelTextStyle: const TextStyle(
                    color: AppColors.pink,
                    fontWeight: FontWeight.w700,
                  ),
                  destinations: [
                    for (final d in destinations)
                      NavigationRailDestination(
                        icon: Icon(d.icon),
                        selectedIcon: Icon(d.selectedIcon),
                        label: Text(d.label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1, color: AppColors.border),
              ],
              Expanded(
                child: IndexedStack(
                  index: index,
                  children: [for (final d in destinations) d.content],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
