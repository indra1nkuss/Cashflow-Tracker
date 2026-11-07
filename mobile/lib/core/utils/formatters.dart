import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final _formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  static String format(num amount) => _formatter.format(amount);

  static String formatCompact(num amount) {
    if (amount >= 1000000000) {
      return 'Rp${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return format(amount);
  }
}

class DateFormatter {
  static final _date = DateFormat('dd/MM/yyyy', 'id_ID');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final _dayDate = DateFormat('EEEE, d MMMM', 'id_ID');

  static String formatDate(DateTime date) => _date.format(date);
  static String formatDateTime(DateTime date) => _dateTime.format(date);
  static String formatMonthYear(DateTime date) => _monthYear.format(date);
  static String formatDayDate(DateTime date) => _dayDate.format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(date);
  }
}

