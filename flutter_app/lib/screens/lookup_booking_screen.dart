import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../services/booking_service.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import 'booking_details_screen.dart';

/// Public entry point from the specification: enter a booking reference and email
/// address to see a booking without creating an account.
class LookupBookingScreen extends StatefulWidget {
  const LookupBookingScreen({super.key});

  @override
  State<LookupBookingScreen> createState() => _LookupBookingScreenState();
}

class _LookupBookingScreenState extends State<LookupBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenceController = TextEditingController();
  final _emailController = TextEditingController();
  late final BookingService _service;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = BookingService(context.read<ApiClient>());
  }

  @override
  void dispose() {
    _referenceController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final booking = await _service.lookup(
        _referenceController.text,
        _emailController.text,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookingDetailsScreen.guest(booking: booking),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Find my booking',
      subtitle: 'Enter your booking reference and the email used to book',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _referenceController,
              textCapitalization: TextCapitalization.characters,
              textInputAction: TextInputAction.next,
              decoration: appInput(
                label: 'Booking reference',
                icon: Icons.confirmation_number_outlined,
                hint: 'TB-XXXXXX',
              ),
              validator: Validators.notEmpty('Enter your booking reference'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: appInput(
                label: 'Email address',
                icon: Icons.mail_outline,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: 'Find booking',
              loading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
