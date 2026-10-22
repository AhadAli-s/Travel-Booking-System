import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../models/admin_dashboard.dart';
import '../providers/staff_auth_provider.dart';
import '../services/admin_service.dart';
import '../widgets/error_state.dart';
import '../widgets/metric_tile.dart';

/// Screen 17: agency home metrics from the specification. Embedded as a tab
/// inside AdminShell, so this is plain content with no Scaffold of its own
/// (the shell owns the single Scaffold, AppBar and sign-out action).
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late final AdminService _service;
  late Future<AdminDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _service = AdminService(context.read<StaffApiClient>().api);
    _future = _service.fetchDashboard();
  }

  Future<void> _refresh() async {
    final next = _service.fetchDashboard();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = context.watch<StaffAuthProvider>().staff;

    return ColoredBox(
      color: const Color(0xFFFAFAFB),
      child: RefreshIndicator(
        color: AppColors.pink,
        onRefresh: _refresh,
        child: FutureBuilder<AdminDashboardData>(
          future: _future,
          builder: (context, snapshot) {
            Widget content;
            if (snapshot.connectionState != ConnectionState.done) {
              content = const Padding(
                padding: EdgeInsets.only(top: 120),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.pink),
                ),
              );
            } else if (snapshot.hasError) {
              content = ErrorState(error: snapshot.error, onRetry: _refresh);
            } else {
              content = _buildGrid(snapshot.data!);
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${staff?.firstName ?? 'there'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          staff?.role ?? '',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 18),
                        content,
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGrid(AdminDashboardData data) {
    final tiles = [
      MetricTile(
        icon: Icons.luggage_outlined,
        label: 'Total bookings',
        value: '${data.totalBookings}',
      ),
      MetricTile(
        icon: Icons.hourglass_top_outlined,
        label: 'Pending bookings',
        value: '${data.pendingBookings}',
        accent: const Color(0xFF8A6D00),
        tint: AppColors.yellowTint,
      ),
      MetricTile(
        icon: Icons.verified_outlined,
        label: 'Confirmed bookings',
        value: '${data.confirmedBookings}',
        accent: AppColors.success,
        tint: AppColors.successTint,
      ),
      MetricTile(
        icon: Icons.cancel_outlined,
        label: 'Cancelled bookings',
        value: '${data.cancelledBookings}',
        accent: AppColors.danger,
        tint: AppColors.dangerTint,
      ),
      MetricTile(
        icon: Icons.flight_takeoff,
        label: 'Travelling soon',
        value: '${data.travellingSoon}',
        accent: AppColors.cyanDark,
        tint: AppColors.cyanTint,
      ),
      MetricTile(
        icon: Icons.account_balance_wallet_outlined,
        label: 'Outstanding payments',
        value: '${data.outstandingPayments}',
      ),
      MetricTile(
        icon: Icons.support_agent_outlined,
        label: 'Open support tickets',
        value: '${data.openSupportTickets}',
        accent: const Color(0xFF8A6D00),
        tint: AppColors.yellowTint,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : (constraints.maxWidth >= 600 ? 3 : 2);
        const spacing = 12.0;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map((tile) => SizedBox(width: width, child: tile))
              .toList(),
        );
      },
    );
  }
}
