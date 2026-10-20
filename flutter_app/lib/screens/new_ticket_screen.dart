import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/ticket_meta.dart';
import '../core/validators.dart';
import '../services/ticket_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Raise a support ticket. [bookingId] pre-fills which booking it is about;
/// General Support tickets have no booking.
class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key, this.bookingId});

  final int? bookingId;

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final TicketService _service;
  String _category = ticketCategories.first;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = TicketService(context.read<ApiClient>());
    if (widget.bookingId == null) _category = 'GeneralSupport';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.createTicket(
        category: _category,
        subject: _subjectController.text,
        description: _descriptionController.text,
        bookingId: widget.bookingId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
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
          'New ticket',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'What is this about?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final category in ticketCategories)
                          ChoiceChip(
                            label: Text(ticketCategoryLabel(category)),
                            selected: _category == category,
                            selectedColor: AppColors.pinkTint,
                            labelStyle: TextStyle(
                              color: _category == category
                                  ? AppColors.pinkDark
                                  : AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: _category == category
                                  ? AppColors.pink
                                  : AppColors.border,
                            ),
                            onSelected: _loading
                                ? null
                                : (_) => setState(() => _category = category),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _subjectController,
                      textInputAction: TextInputAction.next,
                      decoration: appInput(
                        label: 'Subject',
                        icon: Icons.short_text,
                        hint: 'A short summary',
                      ),
                      validator: Validators.notEmpty('Enter a subject'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 6,
                      decoration: appInput(
                        label: 'Describe the issue',
                        icon: Icons.edit_note,
                      ),
                      validator: Validators.notEmpty('Describe the issue'),
                    ),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      ErrorBanner(message: _error!),
                      const SizedBox(height: 12),
                    ],
                    PrimaryButton(
                      label: 'Submit ticket',
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
