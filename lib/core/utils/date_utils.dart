import 'package:intl/intl.dart';

/// Date utility functions
class AppDateUtils {
  AppDateUtils._();

  /// Format timestamp for chat list display
  static String formatChatListTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) return DateFormat.jm().format(dateTime);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(dateTime);
    return DateFormat('dd/MM/yy').format(dateTime);
  }

  /// Format message timestamp (just time)
  static String formatMessageTime(DateTime dateTime) {
    return DateFormat.jm().format(dateTime);
  }

  /// Format separator header in chat (Today, Yesterday, or date)
  static String formatDateHeader(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return DateFormat.yMMMd().format(dateTime);
  }

  /// Check if status is expired (>24 hours)
  static bool isExpired(DateTime createdAt, {int hours = 24}) {
    return DateTime.now().difference(createdAt).inHours >= hours;
  }

  /// Format call duration
  static String formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
