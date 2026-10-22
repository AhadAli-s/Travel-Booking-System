import 'package:flutter/material.dart';

import '../core/theme.dart';

/// Picks a date and a time, and formats them as the "YYYY-MM-DDTHH:mm:00Z"
/// string the API stores for flight and transfer times. These are entered as
/// local airport time and stored and shown exactly as entered (see
/// core/format.dart formatDateTimeUtc), so no timezone conversion happens here.
class DateTimeField extends StatelessWidget {
  const DateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  Future<void> _pick(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (date == null || !context.mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: value == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: value!.hour, minute: value!.minute),
    );
    if (time == null) return;
    onChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = value == null
        ? 'Select date and time'
        : '${value!.year.toString().padLeft(4, '0')}-${value!.month.toString().padLeft(2, '0')}-${value!.day.toString().padLeft(2, '0')}'
              '  ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pick(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.schedule, size: 18),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: value == null ? AppColors.muted : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Converts a DateTimeField value into the "YYYY-MM-DDTHH:mm:00Z" string the API expects.
String? dateTimeFieldValue(DateTime? value) {
  if (value == null) return null;
  final date =
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  final time =
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  return '${date}T$time:00Z';
}
