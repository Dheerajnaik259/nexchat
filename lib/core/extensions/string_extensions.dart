/// String utility extensions
extension StringExtensions on String {
  /// Capitalize first letter
  String get capitalize => isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';

  /// Check if string is a valid email
  bool get isValidEmail => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);

  /// Check if string is a valid phone number
  bool get isValidPhone => RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(replaceAll(' ', ''));

  /// Truncate string with ellipsis
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';

  /// Get initials from a name
  String get initials {
    final parts = trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return isNotEmpty ? this[0].toUpperCase() : '';
  }
}
