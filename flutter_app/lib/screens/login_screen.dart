import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Screen 2: customer login.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
        _emailController.text,
        _passwordController.text,
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
      title: 'Welcome back',
      subtitle: 'Log in to manage your booking',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: appInput(label: 'Email', icon: Icons.mail_outline),
              validator: Validators.email,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: appInput(
                label: 'Password',
                icon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: Validators.notEmpty('Enter your password'),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.cyanDark,
                ),
                onPressed: _loading
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      ),
                child: const Text('Forgot password?'),
              ),
            ),
            if (_error != null) ...[
              ErrorBanner(message: _error!),
              const SizedBox(height: 12),
            ],
            PrimaryButton(
              label: 'Log in',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'New here?',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 20),
            SecondaryButton(
              label: 'Create an account',
              onPressed: _loading
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
