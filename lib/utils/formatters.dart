import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static String formatRate(double rate) {
    final formatter = NumberFormat('#,##0.00', 'es_VE');
    return formatter.format(rate);
  }

  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es_VE');
    return formatter.format(amount);
  }

  static String formatVariation(double variation) {
    final sign = variation >= 0 ? '+' : '';
    return '$sign${variation.toStringAsFixed(2)}';
  }

  static String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} minutos';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inDays} días';
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM', 'es').format(date);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }
}
