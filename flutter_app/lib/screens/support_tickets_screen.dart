import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../core/ticket_meta.dart';
import '../models/ticket.dart';
import '../services/ticket_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/status_chip.dart';
import 'new_ticket_screen.dart';
import 'ticket_thread_screen.dart';

/// Screen 13: support ticket dashboard. Tap a ticket to open its thread,
/// or raise a new one with the + button.
class SupportTicketsScreen extends StatefulWidget {
  const SupportTicketsScreen({super.key});

  @override
  State<SupportTicketsScreen> createState() => _SupportTicketsScreenState();
}

class _SupportTicketsScreenState extends State<SupportTicketsScreen> {
  late final TicketService _service;
  late Future<List<SupportTicket>> _future;

  @override
  void initState() {
    super.initState();
    _service = TicketService(context.read<ApiClient>());
    _future = _service.myTickets();
  }

  Future<void> _refresh() async {
    final next = _service.myTickets();
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TicketThreadScreen(ticketId: ticket.id),
      ),
    );
    if (mounted) _refresh();
  }

  Future<void> _newTicket() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const NewTicketScreen()),
    );
    if (created == true && mounted) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Support',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newTicket,
        backgroundColor: AppColors.pink,
        icon: const Icon(Icons.add),
        label: const Text('New ticket'),
      ),
      body: FutureBuilder<List<SupportTicket>>(
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
          final tickets = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.pink,
            onRefresh: _refresh,
            child: tickets.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 60),
                      EmptyState(
                        icon: Icons.support_agent_outlined,
                        title: 'No support tickets',
                        message: 'Tap "New ticket" if you need help with a booking, payment or anything else.',
                      ),
                    ],
                  )
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                    itemCount: tickets.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final ticket = tickets[index];
                      return Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: _TicketTile(
                            ticket: ticket,
                            onTap: () => _openTicket(ticket),
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

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket, required this.onTap});

  final SupportTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.pinkTint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  ticketCategoryIcon(ticket.category),
                  color: AppColors.pink,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ticketCategoryLabel(ticket.category)}  |  ${formatDate(ticket.updatedAt?.toLocal())}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusChip(status: ticket.status),
            ],
          ),
        ),
      ),
    );
  }
}
