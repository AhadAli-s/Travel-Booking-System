import '../core/json_utils.dart';

class Staff {
  const Staff({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.status,
    this.createdAt,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;

  /// Only present on the staff management list (GET /admin/staff), not on the
  /// staff login response or the "assignedStaff" summary inside a booking.
  final String? status;
  final DateTime? createdAt;

  bool get isActive => status == null || status == 'Active';

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: toInt(json['id']),
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      status: toNullableString(json['status']),
      createdAt: parseDate(json['createdAt']),
    );
  }

  static List<Staff> listFromJson(dynamic value) {
    if (value is! List) return const <Staff>[];
    return value.whereType<Map<String, dynamic>>().map(Staff.fromJson).toList();
  }

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }
}
