import 'package:flutter/material.dart';

import '../core/admin_meta.dart';
import '../core/api_client.dart';
import '../core/format.dart';
import '../models/booking.dart';
import '../models/staff.dart';
import '../services/admin_booking_service.dart';
import '../services/admin_staff_service.dart';
import '../widgets/date_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Change a booking's status. Returns true if it changed.
Future<bool?> showChangeStatusDialog(
  BuildContext context,
  AdminBookingService service,
  Booking booking,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ChangeStatusDialog(service: service, booking: booking),
  );
}

class _ChangeStatusDialog extends StatefulWidget {
  const _ChangeStatusDialog({required this.service, required this.booking});

  final AdminBookingService service;
  final Booking booking;

  @override
  State<_ChangeStatusDialog> createState() => _ChangeStatusDialogState();
}

class _ChangeStatusDialogState extends State<_ChangeStatusDialog> {
  late String _status = widget.booking.status;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.updateStatus(widget.booking.id, _status);
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
      title: const Text('Change status'),
      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in bookingStatuses)
                  DropdownMenuItem(value: s, child: Text(statusLabel(s))),
              ],
              onChanged: (value) => setState(() => _status = value ?? _status),
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

/// Assign or unassign the staff member handling a booking. Returns true if it changed.
Future<bool?> showAssignStaffDialog(
  BuildContext context,
  AdminBookingService bookingService,
  AdminStaffService staffService,
  Booking booking,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _AssignStaffDialog(
      bookingService: bookingService,
      staffService: staffService,
      booking: booking,
    ),
  );
}

class _AssignStaffDialog extends StatefulWidget {
  const _AssignStaffDialog({
    required this.bookingService,
    required this.staffService,
    required this.booking,
  });

  final AdminBookingService bookingService;
  final AdminStaffService staffService;
  final Booking booking;

  @override
  State<_AssignStaffDialog> createState() => _AssignStaffDialogState();
}

class _AssignStaffDialogState extends State<_AssignStaffDialog> {
  late Future<List<Staff>> _staffFuture;
  int? _selected;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _staffFuture = widget.staffService.list();
    _selected = widget.booking.assignedStaff?.id;
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.bookingService.assignStaff(widget.booking.id, _selected);
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
      title: const Text('Assign staff'),
      content: SizedBox(
        width: 340,
        child: FutureBuilder<List<Staff>>(
          future: _staffFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return const Text('Could not load staff.');
            }
            final staff = snapshot.data!.where((s) => s.isActive).toList();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int?>(
                  initialValue: _selected,
                  decoration: const InputDecoration(labelText: 'Assigned to'),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned'),
                    ),
                    for (final s in staff)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text(
                          '${s.fullName} (${staffRoleLabel(s.role)})',
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() => _selected = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  ErrorBanner(message: _error!),
                ],
              ],
            );
          },
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

/// Edit destination, dates, traveller counts and notes. Returns true if saved.
Future<bool?> showEditBookingDialog(
  BuildContext context,
  AdminBookingService service,
  Booking booking,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _EditBookingDialog(service: service, booking: booking),
  );
}

class _EditBookingDialog extends StatefulWidget {
  const _EditBookingDialog({required this.service, required this.booking});

  final AdminBookingService service;
  final Booking booking;

  @override
  State<_EditBookingDialog> createState() => _EditBookingDialogState();
}

class _EditBookingDialogState extends State<_EditBookingDialog> {
  late final _destinationController = TextEditingController(
    text: widget.booking.destination,
  );
  late final _cityController = TextEditingController(
    text: widget.booking.departureCity ?? '',
  );
  late final _airportController = TextEditingController(
    text: widget.booking.departureAirport ?? '',
  );
  late final _adultsController = TextEditingController(
    text: '${widget.booking.numAdults}',
  );
  late final _childrenController = TextEditingController(
    text: '${widget.booking.numChildren}',
  );
  late final _infantsController = TextEditingController(
    text: '${widget.booking.numInfants}',
  );
  late final _notesController = TextEditingController(
    text: widget.booking.notes ?? '',
  );
  late DateTime? _travelDate = widget.booking.travelDate;
  late DateTime? _returnDate = widget.booking.returnDate;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _destinationController.dispose();
    _cityController.dispose();
    _airportController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
    _infantsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final travelDate = dateFieldValue(_travelDate);
    final returnDate = dateFieldValue(_returnDate);
    if (_destinationController.text.trim().isEmpty ||
        travelDate == null ||
        returnDate == null) {
      setState(
        () => _error = 'Destination, travel date and return date are required',
      );
      return;
    }
    if (returnDate.compareTo(travelDate) < 0) {
      setState(() => _error = 'Return date cannot be before travel date');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.updateDetails(
        widget.booking.id,
        destination: _destinationController.text.trim(),
        departureCity: _cityController.text.trim(),
        departureAirport: _airportController.text.trim(),
        travelDate: travelDate,
        returnDate: returnDate,
        numAdults:
            int.tryParse(_adultsController.text) ?? widget.booking.numAdults,
        numChildren:
            int.tryParse(_childrenController.text) ??
            widget.booking.numChildren,
        numInfants:
            int.tryParse(_infantsController.text) ?? widget.booking.numInfants,
        notes: _notesController.text.trim(),
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
      title: const Text('Edit booking'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _destinationController,
                decoration: const InputDecoration(labelText: 'Destination'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Departure city',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _airportController,
                      decoration: const InputDecoration(labelText: 'Airport'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DateField(
                      label: 'Travel date',
                      value: _travelDate,
                      onChanged: (d) => setState(() => _travelDate = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DateField(
                      label: 'Return date',
                      value: _returnDate,
                      onChanged: (d) => setState(() => _returnDate = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _adultsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Adults'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _childrenController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Children'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _infantsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Infants'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Internal notes'),
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
            label: 'Save',
            loading: _loading,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
