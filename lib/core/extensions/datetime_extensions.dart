import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

/// DateTime utility extensions
extension DateTimeExtensions on DateTime {
  /// Format as time (e.g., "2:30 PM")
  String get timeFormatted => DateFormat.jm().format(this);

  /// Format as date (e.g., "Mar 25, 2026")
  String get dateFormatted => DateFormat.yMMMd().format(this);

  /// Format as relative time (e.g., "2 hours ago")
  String get relativeTime => timeago.format(this);

  /// Format for chat list (today: time, this week: day, else: date)
  String get chatListFormatted {
    final now = DateTime.now();
    final diff = now.difference(this);

    if (diff.inDays == 0) return timeFormatted;
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(this);
    return DateFormat('dd/MM/yy').format(this);
  }

  /// Check if this date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if this date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && month == yesterday.month && day == yesterday.day;
  }
}
