import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/admin_meta.dart';
import '../core/api_client.dart';
import '../core/format.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../core/ticket_meta.dart';
import '../models/ticket.dart';
import '../providers/staff_auth_provider.dart';
import '../services/admin_staff_service.dart';
import '../services/admin_ticket_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';
import '../widgets/status_chip.dart';

/// Staff view of a ticket thread: reply, change status and reassign.
/// Administrator and SupportAgent can change status or assignment; every
/// role can read and reply (matching the server's route guards).
class AdminTicketThreadScreen extends StatefulWidget {
  const AdminTicketThreadScreen({super.key, required this.ticketId});

  final int ticketId;

  @override
  State<AdminTicketThreadScreen> createState() =>
      _AdminTicketThreadScreenState();
}

class _AdminTicketThreadScreenState extends State<AdminTicketThreadScreen> {
  late final AdminTicketService _service;
  late final AdminStaffService _staffService;
  late Future<SupportTicket> _future;
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    final api = context.read<StaffApiClient>().api;
    _service = AdminTicketService(api);
    _staffService = AdminStaffService(api);
    _future = _service.getTicket(widget.ticketId);
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final next = _service.getTicket(widget.ticketId);
    setState(() => _future = next);
    try {
      await next;
    } catch (_) {
      // The error is shown by the FutureBuilder.
    }
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendReply() async {
    final message = _replyController.text.trim();
    if (message.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _service.addReply(widget.ticketId, message);
      _replyController.clear();
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) _message(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _changeStatus(String current) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Change status'),
        children: [
          for (final status in ticketStatuses)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(status),
              child: Row(
                children: [
                  StatusChip(status: status),
                  const SizedBox(width: 10),
                  Text(statusLabel(status)),
                ],
              ),
            ),
        ],
      ),
    );
    if (selected == null || selected == current) return;
    try {
      await _service.updateStatus(widget.ticketId, selected);
      _refresh();
    } on ApiException catch (e) {
      _message(e.message);
    }
  }

  Future<void> _assign(int? current) async {
    final staff = await _staffService.list();
    final active = staff.where((s) => s.isActive).toList();
    if (!mounted) return;
    final selected = await showDialog<int?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Assign ticket'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Unassigned'),
          ),
          for (final s in active)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(s.id),
              child: Text('${s.fullName} (${staffRoleLabel(s.role)})'),
            ),
        ],
      ),
    );
    if (selected == current) return;
    try {
      await _service.assign(widget.ticketId, selected);
      _refresh();
    } on ApiException catch (e) {
      _message(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<StaffAuthProvider>().staff?.role ?? '';
    final canManage = roleCanManageTickets(role);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Ticket',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<SupportTicket>(
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
          final ticket = snapshot.data!;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.pink,
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    children: [
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 700),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.subject,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${ticketCategoryLabel(ticket.category)}  |  opened ${formatDate(ticket.createdAt?.toLocal())}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (canManage)
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _changeStatus(ticket.status),
                                        icon: const Icon(
                                          Icons.flag_outlined,
                                          size: 16,
                                        ),
                                        label: Text(statusLabel(ticket.status)),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _assign(null),
                                        icon: const Icon(
                                          Icons.person_add_alt_outlined,
                                          size: 16,
                                        ),
                                        label: const Text('Reassign'),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                StatusChip(status: ticket.status),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Text(
                                  ticket.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.ink,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              for (final reply in ticket.replies)
                                _ReplyBubble(reply: reply),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _ReplyBox(
                controller: _replyController,
                sending: _sending,
                disabled: ticket.isClosed,
                onSend: _sendReply,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReplyBubble extends StatelessWidget {
  const _ReplyBubble({required this.reply});

  final TicketReply reply;

  @override
  Widget build(BuildContext context) {
    // Staff view: staff replies sit on the right (this is "me" here), the
    // customer's own messages sit on the left — the mirror of the customer app.
    final fromStaff = reply.fromStaff;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: fromStaff
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!fromStaff) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.pinkTint,
              child: Icon(Icons.person, size: 18, color: AppColors.pinkDark),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: fromStaff ? AppColors.pink : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(fromStaff ? 14 : 2),
                  bottomRight: Radius.circular(fromStaff ? 2 : 14),
                ),
                border: fromStaff ? null : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromStaff ? 'Support team' : 'Customer',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: fromStaff ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    reply.message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: fromStaff ? Colors.white : AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatDate(reply.createdAt?.toLocal()),
                    style: TextStyle(
                      fontSize: 10,
                      color: fromStaff ? Colors.white70 : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReplyBox extends StatelessWidget {
  const _ReplyBox({
    required this.controller,
    required this.sending,
    required this.disabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool disabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: disabled
                ? const Text(
                    'This ticket is closed and can no longer be replied to.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 13),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: controller,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => onSend(),
                          decoration: InputDecoration(
                            hintText: 'Reply to the customer...',
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.border,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(
                                color: AppColors.pink,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: sending ? null : onSend,
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.pink,
                        ),
                        icon: sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
