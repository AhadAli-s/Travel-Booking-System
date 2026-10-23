import 'package:flutter/material.dart';

import '../core/api_client.dart';
import '../models/booking.dart';
import '../services/admin_booking_service.dart';
import '../widgets/date_field.dart';
import '../widgets/date_time_field.dart';
import '../widgets/error_banner.dart';
import '../widgets/primary_button.dart';

/// Create or edit the flight. Returns true if saved.
Future<bool?> showEditFlightDialog(
  BuildContext context,
  AdminBookingService service,
  int bookingId,
  FlightInfo? flight,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _EditFlightDialog(
      service: service,
      bookingId: bookingId,
      flight: flight,
    ),
  );
}

class _EditFlightDialog extends StatefulWidget {
  const _EditFlightDialog({
    required this.service,
    required this.bookingId,
    required this.flight,
  });

  final AdminBookingService service;
  final int bookingId;
  final FlightInfo? flight;

  @override
  State<_EditFlightDialog> createState() => _EditFlightDialogState();
}

class _EditFlightDialogState extends State<_EditFlightDialog> {
  late final _airlineController = TextEditingController(
    text: widget.flight?.airline ?? '',
  );
  late final _flightNumberController = TextEditingController(
    text: widget.flight?.flightNumber ?? '',
  );
  late final _fromController = TextEditingController(
    text: widget.flight?.departureAirport ?? '',
  );
  late final _toController = TextEditingController(
    text: widget.flight?.arrivalAirport ?? '',
  );
  late final _returnFlightNumberController = TextEditingController(
    text: widget.flight?.returnFlightNumber ?? '',
  );
  late final _baggageController = TextEditingController(
    text: widget.flight?.baggageAllowance ?? '',
  );
  late DateTime? _departureTime = widget.flight?.departureTime;
  late DateTime? _arrivalTime = widget.flight?.arrivalTime;
  late DateTime? _returnDepartureTime = widget.flight?.returnDepartureTime;
  late DateTime? _returnArrivalTime = widget.flight?.returnArrivalTime;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _airlineController.dispose();
    _flightNumberController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _returnFlightNumberController.dispose();
    _baggageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final departureTime = dateTimeFieldValue(_departureTime);
    final arrivalTime = dateTimeFieldValue(_arrivalTime);
    if (_airlineController.text.trim().isEmpty ||
        _flightNumberController.text.trim().isEmpty ||
        _fromController.text.trim().isEmpty ||
        _toController.text.trim().isEmpty ||
        departureTime == null ||
        arrivalTime == null) {
      setState(
        () => _error = 'Airline, flight number, airports, departure and arrival time are required',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.saveFlight(
        widget.bookingId,
        airline: _airlineController.text.trim(),
        flightNumber: _flightNumberController.text.trim(),
        departureAirport: _fromController.text.trim().toUpperCase(),
        arrivalAirport: _toController.text.trim().toUpperCase(),
        departureTime: departureTime,
        arrivalTime: arrivalTime,
        returnFlightNumber: _returnFlightNumberController.text.trim().isEmpty
            ? null
            : _returnFlightNumberController.text.trim(),
        returnDepartureTime: dateTimeFieldValue(_returnDepartureTime),
        returnArrivalTime: dateTimeFieldValue(_returnArrivalTime),
        baggageAllowance: _baggageController.text.trim().isEmpty
            ? null
            : _baggageController.text.trim(),
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
      title: const Text('Flight details'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _airlineController,
                decoration: const InputDecoration(labelText: 'Airline'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _flightNumberController,
                decoration: const InputDecoration(labelText: 'Flight number'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _fromController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'From (airport code)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _toController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'To (airport code)',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DateTimeField(
                label: 'Departs',
                value: _departureTime,
                onChanged: (d) => setState(() => _departureTime = d),
              ),
              const SizedBox(height: 10),
              DateTimeField(
                label: 'Arrives',
                value: _arrivalTime,
                onChanged: (d) => setState(() => _arrivalTime = d),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(),
              ),
              TextField(
                controller: _returnFlightNumberController,
                decoration: const InputDecoration(
                  labelText: 'Return flight number (optional)',
                ),
              ),
              const SizedBox(height: 10),
              DateTimeField(
                label: 'Return departs (optional)',
                value: _returnDepartureTime,
                onChanged: (d) => setState(() => _returnDepartureTime = d),
              ),
              const SizedBox(height: 10),
              DateTimeField(
                label: 'Return arrives (optional)',
                value: _returnArrivalTime,
                onChanged: (d) => setState(() => _returnArrivalTime = d),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _baggageController,
                decoration: const InputDecoration(
                  labelText: 'Baggage allowance',
                ),
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

/// Create or edit the hotel. Returns true if saved.
Future<bool?> showEditHotelDialog(
  BuildContext context,
  AdminBookingService service,
  int bookingId,
  HotelInfo? hotel,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) =>
        _EditHotelDialog(service: service, bookingId: bookingId, hotel: hotel),
  );
}

class _EditHotelDialog extends StatefulWidget {
  const _EditHotelDialog({
    required this.service,
    required this.bookingId,
    required this.hotel,
  });

  final AdminBookingService service;
  final int bookingId;
  final HotelInfo? hotel;

  @override
  State<_EditHotelDialog> createState() => _EditHotelDialogState();
}

class _EditHotelDialogState extends State<_EditHotelDialog> {
  late final _nameController = TextEditingController(
    text: widget.hotel?.hotelName ?? '',
  );
  late final _addressController = TextEditingController(
    text: widget.hotel?.hotelAddress ?? '',
  );
  late final _roomTypeController = TextEditingController(
    text: widget.hotel?.roomType ?? '',
  );
  late final _roomsController = TextEditingController(
    text: '${widget.hotel?.numRooms ?? 1}',
  );
  late final _confirmationController = TextEditingController(
    text: widget.hotel?.confirmationNumber ?? '',
  );
  late String _boardBasis = widget.hotel?.boardBasis ?? 'All Inclusive';
  late DateTime? _checkIn = widget.hotel?.checkInDate;
  late DateTime? _checkOut = widget.hotel?.checkOutDate;
  bool _loading = false;
  String? _error;

  static const _boardOptions = [
    'Room Only',
    'Bed and Breakfast',
    'Half Board',
    'Full Board',
    'All Inclusive',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _roomTypeController.dispose();
    _roomsController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final checkIn = dateFieldValue(_checkIn);
    final checkOut = dateFieldValue(_checkOut);
    if (_nameController.text.trim().isEmpty ||
        checkIn == null ||
        checkOut == null) {
      setState(
        () => _error = 'Hotel name, check-in and check-out are required',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.saveHotel(
        widget.bookingId,
        hotelName: _nameController.text.trim(),
        checkInDate: checkIn,
        checkOutDate: checkOut,
        hotelAddress: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        roomType: _roomTypeController.text.trim().isEmpty
            ? null
            : _roomTypeController.text.trim(),
        numRooms: int.tryParse(_roomsController.text),
        boardBasis: _boardBasis,
        confirmationNumber: _confirmationController.text.trim().isEmpty
            ? null
            : _confirmationController.text.trim(),
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
      title: const Text('Hotel details'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Hotel name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _roomTypeController,
                      decoration: const InputDecoration(labelText: 'Room type'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _roomsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Rooms'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _boardBasis,
                decoration: const InputDecoration(labelText: 'Board basis'),
                items: [
                  for (final b in _boardOptions)
                    DropdownMenuItem(value: b, child: Text(b)),
                ],
                onChanged: (value) =>
                    setState(() => _boardBasis = value ?? _boardBasis),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DateField(
                      label: 'Check-in',
                      value: _checkIn,
                      onChanged: (d) => setState(() => _checkIn = d),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DateField(
                      label: 'Check-out',
                      value: _checkOut,
                      onChanged: (d) => setState(() => _checkOut = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Hotel confirmation number',
                ),
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

/// Create or edit the airport transfer. Returns true if saved.
Future<bool?> showEditTransferDialog(
  BuildContext context,
  AdminBookingService service,
  int bookingId,
  TransferInfo? transfer,
) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _EditTransferDialog(
      service: service,
      bookingId: bookingId,
      transfer: transfer,
    ),
  );
}

class _EditTransferDialog extends StatefulWidget {
  const _EditTransferDialog({
    required this.service,
    required this.bookingId,
    required this.transfer,
  });

  final AdminBookingService service;
  final int bookingId;
  final TransferInfo? transfer;

  @override
  State<_EditTransferDialog> createState() => _EditTransferDialogState();
}

class _EditTransferDialogState extends State<_EditTransferDialog> {
  late final _pickupController = TextEditingController(
    text: widget.transfer?.pickupLocation ?? '',
  );
  late final _dropoffController = TextEditingController(
    text: widget.transfer?.dropoffLocation ?? '',
  );
  late DateTime? _pickupTime = widget.transfer?.pickupTime;
  late String _status = widget.transfer?.transferStatus ?? 'Pending';
  bool _loading = false;
  String? _error;

  static const _statuses = ['Pending', 'Confirmed', 'Completed', 'Cancelled'];

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.service.saveTransfer(
        widget.bookingId,
        pickupLocation: _pickupController.text.trim().isEmpty
            ? null
            : _pickupController.text.trim(),
        pickupTime: dateTimeFieldValue(_pickupTime),
        dropoffLocation: _dropoffController.text.trim().isEmpty
            ? null
            : _dropoffController.text.trim(),
        transferStatus: _status,
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
      title: const Text('Airport transfer'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _pickupController,
                decoration: const InputDecoration(
                  labelText: 'Pick-up location',
                ),
              ),
              const SizedBox(height: 10),
              DateTimeField(
                label: 'Pick-up time',
                value: _pickupTime,
                onChanged: (d) => setState(() => _pickupTime = d),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _dropoffController,
                decoration: const InputDecoration(
                  labelText: 'Drop-off location',
                ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Transfer status'),
                items: [
                  for (final s in _statuses)
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? _status),
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
