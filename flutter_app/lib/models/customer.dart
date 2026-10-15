class Customer {
  const Customer({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
  });

  final int id;
  final String fullName;
  final String email;
  final String? phone;

  factory Customer.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    return Customer(
      id: id is num ? id.toInt() : 0,
      fullName: (json['fullName'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: json['phone'] == null ? null : json['phone'].toString(),
    );
  }

  String get firstName {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.first;
  }
}
