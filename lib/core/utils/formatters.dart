import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Formatting utilities for currency, numbers, dates
class Formatters {
  Formatters._();

  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.##', 'ar');
    return '${formatter.format(amount)} ${AppConstants.currencySymbol}';
  }

  static String formatDate(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd', 'ar').format(dateTime);
  }

  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a', 'ar').format(dateTime);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(dateTime);
  }
}
