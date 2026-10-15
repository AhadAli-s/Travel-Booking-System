import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import '../core/theme.dart';

/// Screen 3: customer registration.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phone: _phoneController.text,
      );
      // The auth gate now shows the dashboard. Close this page so it is not left on top.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Track every booking in one place',
      showBack: true,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: appInput(
                label: 'Full name',
                icon: Icons.person_outline,
              ),
              validator: Validators.fullName,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: appInput(label: 'Email', icon: Icons.mail_outline),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: appInput(
                label: 'Phone (optional)',
                icon: Icons.phone_outlined,
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.next,
              decoration: appInput(
                label: 'Password',
                icon: Icons.lock_outline,
                hint: 'At least 8 characters',
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: Validators.newPassword,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _confirmController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: appInput(
                label: 'Confirm password',
                icon: Icons.lock_outline,
              ),
              validator: Validators.matches(() => _passwordController.text),
            ),
            const SizedBox(height: 20),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: 'Sign up',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.cyanDark),
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('I already have an account'),
            ),
          ],
        ),
      ),
    );
  }
}
