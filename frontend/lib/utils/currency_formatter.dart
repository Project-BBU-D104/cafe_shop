import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(
    double amount,
    Map<String, dynamic>? currency,
  ) {
    if (currency == null) {
      return amount.toStringAsFixed(2);
    }

    final String symbol = currency['symbol'] ?? '';
    final String code = currency['name'] ?? '';

    final int decimalDigits =
        code.toUpperCase() == 'KHR' ? 0 : 2;

    return NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits,
    ).format(amount);
  }
}