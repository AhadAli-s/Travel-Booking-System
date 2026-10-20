import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/dashboard.dart';
import '../providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../widgets/info_card.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';
import '../widgets/trip_hero_card.dart';
import 'booking_details_screen.dart';
import 'documents_screen.dart';
import 'notifications_screen.dart';
import 'payments_screen.dart';
import 'support_tickets_screen.dart';

/// Screen 5: customer dashboard with the travel countdown and four summary cards.
class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() =>
      _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  late final DashboardService _service;
  late Future<DashboardData> _future;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _service = DashboardService(context.read<ApiClient>());
    _future = _load();
  }

  Future<DashboardData> _load() async {
    final unreadFuture = _service.unreadNotificationCount().catchError(
      (Object _) => 0,
    );
    final data = await _service.fetchDashboard();
    final unread = await unreadFuture;
    if (mounted) setState(() => _unread = unread);
    return data;
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  /// Opens a page and reloads the dashboard when the customer comes back.
  Future<void> _push(Widget screen) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen));
    if (mounted) _refresh();
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to see your bookings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.pink),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = context.watch<AuthProvider>().customer?.firstName ?? 'there';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Manage My Booking',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => _push(const NotificationsScreen()),
            icon: Badge(
              label: Text('$_unread'),
              isLabelVisible: _unread > 0,
              backgroundColor: AppColors.yellow,
              textColor: AppColors.ink,
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.pink,
        onRefresh: _refresh,
        child: FutureBuilder<DashboardData>(
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
              final error = snapshot.error;
              content = _ErrorState(
                message: error is ApiException
                    ? error.message
                    : 'Could not load your dashboard.',
                onRetry: _refresh,
              );
            } else {
              content = _buildContent(snapshot.data!);
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
                          'Hello, $name',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Here is what is happening with your holiday.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
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

  Widget _buildContent(DashboardData data) {
    final trip = data.trip;
    final payment = data.payment;

    final statusCard = InfoCard(
      icon: Icons.verified_outlined,
      title: 'Booking status',
      value: trip == null ? '-' : statusLabel(trip.status),
      subtitle: trip == null ? 'No upcoming trip' : trip.bookingReference,
      accent: AppColors.cyanDark,
      tint: AppColors.cyanTint,
      valueColor: trip == null
          ? AppColors.muted
          : StatusChip.colorFor(trip.status),
      onTap: trip == null
          ? null
          : () => _push(BookingDetailsScreen(bookingId: trip.bookingId)),
    );

    final String paymentValue;
    final String paymentSubtitle;
    if (payment == null) {
      paymentValue = '-';
      paymentSubtitle = 'No payment due';
    } else if (payment.remainingBalance <= 0) {
      paymentValue = 'Paid';
      paymentSubtitle = 'Nothing left to pay';
    } else {
      paymentValue = formatMoney(payment.remainingBalance);
      paymentSubtitle = payment.paymentDueDate == null
          ? 'Remaining'
          : 'Remaining, due ${formatDate(payment.paymentDueDate)}';
    }
    final paymentCard = InfoCard(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Payment',
      value: paymentValue,
      subtitle: paymentSubtitle,
      accent: AppColors.pink,
      tint: AppColors.pinkTint,
      onTap: trip == null
          ? null
          : () => _push(
              PaymentsScreen(
                bookingId: trip.bookingId,
                reference: trip.bookingReference,
              ),
            ),
    );

    final documentsCard = InfoCard(
      icon: Icons.description_outlined,
      title: 'Documents',
      value: '${data.documentsAvailable}',
      subtitle: 'Available',
      accent: AppColors.cyanDark,
      tint: AppColors.cyanTint,
      onTap: trip == null
          ? null
          : () => _push(DocumentsScreen(bookingId: trip.bookingId)),
    );

    final supportCard = InfoCard(
      icon: Icons.support_agent_outlined,
      title: 'Support',
      value: '${data.activeTickets}',
      subtitle: data.activeTickets == 1 ? 'Active ticket' : 'Active tickets',
      accent: const Color(0xFF8A6D00),
      tint: AppColors.yellowTint,
      onTap: () => _push(const SupportTicketsScreen()),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (trip != null)
          TripHeroCard(
            trip: trip,
            onTap: () => _push(BookingDetailsScreen(bookingId: trip.bookingId)),
          )
        else
          const _NoTripCard(),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 4 : 2;
            const spacing = 12.0;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                statusCard,
                paymentCard,
                documentsCard,
                supportCard,
              ].map((card) => SizedBox(width: width, child: card)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _NoTripCard extends StatelessWidget {
  const _NoTripCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.cyanTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.beach_access_outlined,
            color: AppColors.cyanDark,
            size: 40,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No upcoming trips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'When you book a holiday on the agency website it appears here automatically.',
                  style: TextStyle(color: AppColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.dangerTint,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            color: AppColors.danger,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.danger, fontSize: 15),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            child: PrimaryButton(label: 'Try again', onPressed: onRetry),
          ),
        ],
      ),
    );
  }
}
