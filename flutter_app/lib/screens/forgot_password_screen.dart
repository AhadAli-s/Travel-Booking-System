import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Screen 4: reset password in two steps.
/// Step 1 asks for the email. Step 2 takes the reset code and the new password.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _requestKey = GlobalKey<FormState>();
  final _resetKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _step = 0;
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  String? _devToken;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (!_requestKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final devToken = await context.read<AuthProvider>().requestPasswordReset(
        _emailController.text,
      );
      if (!mounted) return;
      setState(() {
        _step = 1;
        _devToken = devToken;
        if (devToken != null) _codeController.text = devToken;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().resetPassword(
        _codeController.text,
        _passwordController.text,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Password updated. You can log in now.')),
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
      title: 'Reset password',
      subtitle: _step == 0
          ? 'Enter your email and we will send you a reset code'
          : 'Enter the reset code and choose a new password',
      showBack: true,
      child: _step == 0 ? _buildRequestStep() : _buildResetStep(),
    );
  }

  Widget _buildRequestStep() {
    return Form(
      key: _requestKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _requestCode(),
            decoration: appInput(label: 'Email', icon: Icons.mail_outline),
            validator: Validators.email,
          ),
          const SizedBox(height: 20),
          if (_error != null) ...[
            ErrorBanner(message: _error!),
            const SizedBox(height: 12),
          ],
          PrimaryButton(
            label: 'Send reset code',
            loading: _loading,
            onPressed: _requestCode,
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _devToken != null
                  ? AppColors.yellowTint
                  : AppColors.cyanTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _devToken != null
                  ? 'Development mode: the server returned your reset code and it is filled in below. In production it is sent by email.'
                  : 'If that email is registered, a reset code has been sent to it.',
              style: const TextStyle(color: AppColors.ink, fontSize: 13),
            ),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _codeController,
            textInputAction: TextInputAction.next,
            decoration: appInput(label: 'Reset code', icon: Icons.key_outlined),
            validator: Validators.notEmpty('Enter the reset code'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
            decoration: appInput(
              label: 'New password',
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
            onFieldSubmitted: (_) => _resetPassword(),
            decoration: appInput(
              label: 'Confirm new password',
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
            label: 'Update password',
            loading: _loading,
            onPressed: _resetPassword,
          ),
          const SizedBox(height: 8),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.cyanDark),
            onPressed: _loading
                ? null
                : () => setState(() {
                    _step = 0;
                    _error = null;
                  }),
            child: const Text('Use a different email'),
          ),
        ],
      ),
    );
  }
}
