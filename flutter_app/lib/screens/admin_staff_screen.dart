import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/admin_meta.dart';
import '../core/api_client.dart';
import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../models/staff.dart';
import '../providers/staff_auth_provider.dart';
import '../services/admin_staff_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/error_state.dart';
import '../widgets/primary_button.dart';

/// Screen 23: staff accounts. Administrator only — the server enforces this
/// too, and AdminShell hides this tab from every other role.
class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  late final AdminStaffService _service;
  late Future<List<Staff>> _future;

  @override
  void initState() {
    super.initState();
    _service = AdminStaffService(context.read<StaffApiClient>().api);
    _future = _service.list();
  }

  void _refresh() => setState(() => _future = _service.list());

  Future<void> _create() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => _CreateStaffDialog(service: _service),
    );
    if (created == true) _refresh();
  }

  Future<void> _edit(Staff staff) async {
    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _EditStaffDialog(service: _service, staff: staff),
    );
    if (changed == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final selfId = context.watch<StaffAuthProvider>().staff?.id;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _create,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.pink,
                  ),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Add staff'),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<List<Staff>>(
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
                        onRetry: () async => _refresh(),
                      );
                    }
                    final staff = snapshot.data!;
                    if (staff.isEmpty) {
                      return const EmptyState(
                        icon: Icons.badge_outlined,
                        title: 'No staff accounts',
                        message: 'Add a staff account to get started.',
                      );
                    }
                    return ListView.separated(
                      itemCount: staff.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final member = staff[index];
                        return _StaffTile(
                          staff: member,
                          isSelf: member.id == selfId,
                          onTap: () => _edit(member),
                        );
                      },
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

class _StaffTile extends StatelessWidget {
  const _StaffTile({
    required this.staff,
    required this.isSelf,
    required this.onTap,
  });

  final Staff staff;
  final bool isSelf;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = staff.isActive;
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
              CircleAvatar(
                radius: 20,
                backgroundColor: active
                    ? AppColors.cyanTint
                    : AppColors.dangerTint,
                child: Text(
                  staff.fullName.isNotEmpty
                      ? staff.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: active ? AppColors.cyanDark : AppColors.danger,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          staff.fullName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                        if (isSelf) ...[
                          const SizedBox(width: 6),
                          const Text(
                            '(you)',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      staff.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    staffRoleLabel(staff.role),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      color: active ? AppColors.success : AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateStaffDialog extends StatefulWidget {
  const _CreateStaffDialog({required this.service});

  final AdminStaffService service;

  @override
  State<_CreateStaffDialog> createState() => _CreateStaffDialogState();
}

class _CreateStaffDialogState extends State<_CreateStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = staffRoles[1];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
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
      await widget.service.create(
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _role,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add staff member'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: Validators.fullName,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: Validators.email,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary password',
                  helperText: 'At least 8 characters',
                ),
                validator: Validators.newPassword,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [
                  for (final r in staffRoles)
                    DropdownMenuItem(value: r, child: Text(staffRoleLabel(r))),
                ],
                onChanged: (value) => setState(() => _role = value ?? _role),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                ErrorBanner(message: _error!),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 110,
          child: PrimaryButton(
            label: 'Create',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}

class _EditStaffDialog extends StatefulWidget {
  const _EditStaffDialog({required this.service, required this.staff});

  final AdminStaffService service;
  final Staff staff;

  @override
  State<_EditStaffDialog> createState() => _EditStaffDialogState();
}

class _EditStaffDialogState extends State<_EditStaffDialog> {
  late final _nameController = TextEditingController(
    text: widget.staff.fullName,
  );
  late String _role = widget.staff.role;
  late bool _active = widget.staff.isActive;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a name');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.update(
        widget.staff.id,
        fullName: _nameController.text.trim(),
        role: _role,
        status: _active ? 'Active' : 'Inactive',
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selfId = context.read<StaffAuthProvider>().staff?.id;
    final isSelf = widget.staff.id == selfId;

    return AlertDialog(
      title: const Text('Edit staff member'),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.staff.email,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Full name'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: [
                for (final r in staffRoles)
                  DropdownMenuItem(value: r, child: Text(staffRoleLabel(r))),
              ],
              onChanged: isSelf
                  ? null
                  : (value) => setState(() => _role = value ?? _role),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Active'),
              value: _active,
              onChanged: isSelf
                  ? null
                  : (value) => setState(() => _active = value),
            ),
            if (isSelf)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'You cannot change your own role or deactivate your own account.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              ErrorBanner(message: _error!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        SizedBox(
          width: 110,
          child: PrimaryButton(
            label: 'Save',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
