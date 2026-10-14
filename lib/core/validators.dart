/// Form validators. Rules match the server (backend/src/utils/authValidation.js).
class Validators {
  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  static final RegExp _phone = RegExp(r'^[0-9+\-\s()]{7,20}$');

  static String? fullName(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 2) return 'Enter your full name';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// Optional field. Empty is fine.
  static String? phone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    if (!_phone.hasMatch(text)) return 'Enter a valid phone number';
    return null;
  }

  static String? newPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a password';
    if (value.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? Function(String?) notEmpty(String message) {
    return (String? value) =>
        (value == null || value.trim().isEmpty) ? message : null;
  }

  static String? Function(String?) matches(String Function() original) {
    return (String? value) =>
        value == original() ? null : 'Passwords do not match';
  }
}
