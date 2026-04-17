/// Input validators for forms
class Validators {
  Validators._();

  /// Validate phone number
  static String? phoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  /// Validate OTP
  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (!RegExp(r'^\d{6}$').hasMatch(value)) return 'OTP must contain only numbers';
    return null;
  }

  /// Validate display name
  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name must be under 50 characters';
    return null;
  }

  /// Validate username
  static String? username(String? value) {
    if (value == null || value.isEmpty) return null; // optional
    if (value.length < 3) return 'Username must be at least 3 characters';
    if (value.length > 30) return 'Username must be under 30 characters';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores';
    }
    return null;
  }

  /// Validate bio
  static String? bio(String? value) {
    if (value == null) return null;
    if (value.length > 150) return 'Bio must be under 150 characters';
    return null;
  }

  /// Validate group name
  static String? groupName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Group name is required';
    if (value.trim().length > 100) return 'Group name must be under 100 characters';
    return null;
  }

  /// Validate message
  static String? message(String? value) {
    if (value == null || value.trim().isEmpty) return 'Message cannot be empty';
    if (value.length > 4096) return 'Message too long';
    return null;
  }
}
