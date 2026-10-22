import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/staff_api_client.dart';
import '../core/theme.dart';
import '../models/admin_customer.dart';
import '../services/admin_customer_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import '../widgets/search_field.dart';
import 'admin_customer_detail_screen.dart';

/// Screen 18: customer management. Search and open a customer to see their
/// bookings, tickets and contact history. Embedded as a shell tab (plain
/// content, no Scaffold of its own).
class AdminCustomersScreen extends StatefulWidget {
  const AdminCustomersScreen({super.key});

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  late final AdminCustomerService _service;
  late Future<(int, List<CustomerSummary>)> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _service = AdminCustomerService(context.read<StaffApiClient>().api);
    _future = _service.list();
  }

  void _load() {
    setState(() => _future = _service.list(search: _search));
  }

  Future<void> _openCustomer(CustomerSummary customer) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminCustomerDetailScreen(customerId: customer.id),
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
              SearchField(
                hint: 'Search by name, email or phone',
                onChanged: (value) {
                  _search = value;
                  _load();
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: FutureBuilder<(int, List<CustomerSummary>)>(
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
                    final (total, customers) = snapshot.data!;
                    if (customers.isEmpty) {
                      return const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No customers found',
                        message: 'Try a different search.',
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '$total customer${total == 1 ? '' : 's'}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListView.separated(
                            itemCount: customers.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) => _CustomerTile(
                              customer: customers[index],
                              onTap: () => _openCustomer(customers[index]),
                            ),
                          ),
                        ),
                      ],
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

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({required this.customer, required this.onTap});

  final CustomerSummary customer;
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.pinkTint,
                child: Text(
                  customer.fullName.isNotEmpty
                      ? customer.fullName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.pinkDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.fullName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      customer.email,
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
                    '${customer.totalBookings} booking${customer.totalBookings == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  if (customer.activeBookings > 0)
                    Text(
                      '${customer.activeBookings} active',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
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
