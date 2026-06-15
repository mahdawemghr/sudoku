import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _displayFormat = DateFormat('MMM d, yyyy');

  /// Formats a [DateTime] as "Jun 15, 2026".
  static String format(DateTime dateTime) {
    return _displayFormat.format(dateTime);
  }

  /// Formats a [DateTime] as a short date "Jun 15".
  static String formatShort(DateTime dateTime) {
    return DateFormat('MMM d').format(dateTime);
  }

  /// Formats a [DateTime] with time "Jun 15, 2026 08:15".
  static String formatWithTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy HH:mm').format(dateTime);
  }
}
