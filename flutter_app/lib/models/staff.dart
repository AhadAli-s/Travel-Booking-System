class Staff {
  const Staff({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;

  factory Staff.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return Staff(
      id: id is num ? id.toInt() : 0,
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
    );
  }

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }
}
