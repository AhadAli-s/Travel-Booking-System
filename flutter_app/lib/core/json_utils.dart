/// The API returns money as numbers in some places and strings ("2450.00") in others.
double toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

String? toNullableString(dynamic value) => value?.toString();

/// Parses "YYYY-MM-DD" or a full ISO date time. Returns null when missing or invalid.
DateTime? parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
