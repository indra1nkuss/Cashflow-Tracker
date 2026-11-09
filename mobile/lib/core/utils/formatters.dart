import 'package:intl/intl.dart';

class CurrencyFormatter {
  static NumberFormat get _formatter => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp',
        decimalDigits: 0,
      );

  static String format(num amount) {
    try {
      return _formatter.format(amount);
    } catch (_) {
      // Fallback manual formatter without dependency on locale data
      final parts = amount.toStringAsFixed(0);
      final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
      final formatted = parts.replaceAllMapped(reg, (Match m) => '${m[1]}.');
      return 'Rp$formatted';
    }
  }

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
  static const List<String> _indonesianMonths = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _indonesianDays = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static String formatDate(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy', 'id_ID').format(date);
    } catch (_) {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      return '$d/$m/${date.year}';
    }
  }

  static String formatDateTime(DateTime date) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(date);
    } catch (_) {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      final h = date.hour.toString().padLeft(2, '0');
      final min = date.minute.toString().padLeft(2, '0');
      return '$d/$m/${date.year} $h:$min';
    }
  }

  static String formatMonthYear(DateTime date) {
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      final monthName = _indonesianMonths[date.month - 1];
      return '$monthName ${date.year}';
    }
  }

  static String formatDayDate(DateTime date) {
    try {
      return DateFormat('EEEE, d MMMM', 'id_ID').format(date);
    } catch (_) {
      final dayName = _indonesianDays[date.weekday - 1];
      final monthName = _indonesianMonths[date.month - 1];
      return '$dayName, ${date.day} $monthName';
    }
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return formatDate(date);
  }
}
