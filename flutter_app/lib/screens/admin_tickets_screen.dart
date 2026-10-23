import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/format.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../core/ticket_meta.dart';
import '../models/ticket.dart';
import '../services/admin_ticket_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/status_chip.dart';
import 'admin_ticket_thread_screen.dart';

/// Screen 21: support ticket management. Filter by status and open a ticket
/// to reply, change status or reassign. Embedded as a shell tab.
class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  late final AdminTicketService _service;
  late Future<List<SupportTicket>> _future;
  String? _statusFilter = 'Open';

  @override
  void initState() {
    super.initState();
    _service = AdminTicketService(context.read<StaffApiClient>().api);
    _future = _service.list(status: _statusFilter);
  }

  void _load() {
    setState(() => _future = _service.list(status: _statusFilter));
  }

  Future<void> _openTicket(SupportTicket ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminTicketThreadScreen(ticketId: ticket.id),
      ),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _statusFilter == null,
                      onTap: () {
                        _statusFilter = null;
                        _load();
                      },
                    ),
                    for (final status in ticketStatuses)
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _FilterChip(
                          label: statusLabel(status),
                          selected: _statusFilter == status,
                          onTap: () {
                            _statusFilter = status;
                            _load();
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: FutureBuilder<List<SupportTicket>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.pink),
                      );
                    }
                    if (snapshot.hasError) {
                      return ErrorState(
                        error: snapshot.error,
                        onRetry: () async => _load(),
                      );
                    }
                    final tickets = snapshot.data!;
                    if (tickets.isEmpty) {
                      return const EmptyState(
                        icon: Icons.support_agent_outlined,
                        title: 'No tickets found',
                        message: 'Try a different filter.',
                      );
                    }
                    return ListView.separated(
                      itemCount: tickets.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _TicketTile(
                        ticket: tickets[index],
                        onTap: () => _openTicket(tickets[index]),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.pinkTint,
      labelStyle: TextStyle(
        color: selected ? AppColors.pinkDark : AppColors.ink,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
      side: BorderSide(color: selected ? AppColors.pink : AppColors.border),
      backgroundColor: Colors.white,
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
