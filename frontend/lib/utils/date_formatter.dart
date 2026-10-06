import 'package:intl/intl.dart';

class DateFormatter {
  static String formatDate(
    DateTime? date, {
    String pattern = 'dd-MM-yyyy',
  }) {
    if (date == null) return '';

    return DateFormat(pattern).format(date);
  }

  static String formatDateTime(DateTime? date) {
    if (date == null) return '';

    return DateFormat('dd-MM-yyyy HH:mm').format(date);
  }

  static String formatMonth(DateTime? date) {
    if (date == null) return '';

    return DateFormat('MMMM yyyy').format(date);
  }

  static String formatTime(DateTime? date) {
    if (date == null) return '';

    return DateFormat('HH:mm').format(date);
  }
}