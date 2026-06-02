import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  /// Tasa principal: "554,43"
  static String formatRate(double rate) {
    final formatter = NumberFormat('#,##0.00', 'es_VE');
    return formatter.format(rate);
  }

  /// Montos calculadora: "1.234,56"
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,##0.00', 'es_VE');
    return formatter.format(amount);
  }

  /// Variación %: "+0.42%" o "-0.05%"
  static String formatVariation(double variation) {
    final sign = variation >= 0 ? '+' : '';
    return '$sign${variation.toStringAsFixed(2)}%';
  }

  /// Spread: "+32.3%"
  static String formatSpread(double pct) {
    final sign = pct >= 0 ? '+' : '';
    return '$sign${pct.toStringAsFixed(1)}%';
  }

  static String timeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'hace un momento';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} horas';
    return 'hace ${diff.inDays} días';
  }

  static String formatDate(DateTime date) {
    return DateFormat('d MMM', 'es').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM', 'es').format(date);
  }

  static String formatDateFull(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'es').format(date);
  }

  static String formatDateHeader(DateTime date) {
    final dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    return '${dayNames[date.weekday % 7]}, ${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}
