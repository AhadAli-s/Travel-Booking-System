import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../services/notification_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';

/// Screen 14: in-app notifications (confirmations, payments, balance reminders,
/// flight changes, document availability).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificationService _service;
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _service = NotificationService(context.read<ApiClient>());
    _future = _service.list();
  }

  Future<void> _refresh() async {
    final next = _service.list();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _service.markAllRead();
      _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _onTap(AppNotification notification) async {
    if (!notification.isRead) {
      try {
        await _service.markRead(notification.id);
        _refresh();
      } on ApiException {
        // Not critical if this fails; the notification stays unread.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<AppNotification>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.pink),
            );
          }
          if (snapshot.hasError) {
            return ErrorState(error: snapshot.error, onRetry: _refresh);
          }
          final notifications = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: notifications.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      const EmptyState(
                        icon: Icons.notifications_none,
                        title: 'No notifications yet',
                        message: 'Updates about your booking, payments and documents appear here.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: _NotificationTile(
                            notification: notification,
                            onTap: () => _onTap(notification),
                          ),
                        ),
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'TicketReply':
    case 'TicketResolved':
      return Icons.support_agent_outlined;
    case 'PaymentReceived':
    case 'PaymentReminder':
      return Icons.account_balance_wallet_outlined;
    case 'BookingStatusChanged':
      return Icons.verified_outlined;
    case 'DocumentUploaded':
      return Icons.description_outlined;
    case 'FlightChange':
      return Icons.flight_outlined;
    default:
      return Icons.notifications_none;
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final unread = !notification.isRead;
    return Material(
      color: unread ? AppColors.pinkTint : Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: unread ? AppColors.pink.withAlpha(60) : AppColors.border,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: unread ? Colors.white : AppColors.cyanTint,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFor(notification.type),
                  size: 19,
                  color: AppColors.cyanDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: AppColors.ink,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatDate(notification.createdAt?.toLocal()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 4, left: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.pink,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
