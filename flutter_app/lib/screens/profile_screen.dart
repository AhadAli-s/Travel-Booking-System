import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../providers/auth_provider.dart';
import '../services/profile_service.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Screen 15: view and edit name and phone. Email is fixed (it is the login).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final ProfileService _service;
  bool _editing = false;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = ProfileService(context.read<ApiClient>());
    final customer = context.read<AuthProvider>().customer;
    _nameController = TextEditingController(text: customer?.fullName ?? '');
    _phoneController = TextEditingController(text: customer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _service.update(
        fullName: _nameController.text,
        phone: _phoneController.text,
      );
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Profile updated.')));
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    final customer = context.watch<AuthProvider>().customer;
    final email = customer?.email ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      appBar: AppBar(
        backgroundColor: AppColors.pink,
        foregroundColor: Colors.white,
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.pinkTint,
                          child: Text(
                            (customer?.firstName.isNotEmpty ?? false)
                                ? customer!.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.pinkDark,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          customer?.fullName ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: _editing,
                          textCapitalization: TextCapitalization.words,
                          decoration: appInput(
                            label: 'Full name',
                            icon: Icons.person_outline,
                          ),
                          validator: Validators.fullName,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          initialValue: email,
                          enabled: false,
                          decoration: appInput(
                            label: 'Email',
                            icon: Icons.mail_outline,
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          enabled: _editing,
                          keyboardType: TextInputType.phone,
                          decoration: appInput(
                            label: 'Phone',
                            icon: Icons.phone_outlined,
                          ),
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 20),
                        if (_error != null) ...[
                          ErrorBanner(message: _error!),
                          const SizedBox(height: 12),
                        ],
                        if (_editing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() {
                                          _editing = false;
                                          _error = null;
                                          _nameController.text =
                                              customer?.fullName ?? '';
                                          _phoneController.text =
                                              customer?.phone ?? '';
                                        }),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(52),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Save',
                                  loading: _loading,
                                  onPressed: _save,
                                ),
                              ),
                            ],
                          )
                        else
                          PrimaryButton(
                            label: 'Edit profile',
                            onPressed: () => setState(() => _editing = true),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, color: AppColors.danger),
                    label: const Text(
                      'Log out',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
