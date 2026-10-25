/// Small formatting helpers (kept dependency-free, no `intl` package needed).
class Fmt {
  Fmt._();

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  /// 25 Oct 2026
  static String date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Mon, 25 Oct
  static String shortDate(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

  /// Mon
  static String weekday(int weekday) => _weekdays[weekday - 1];

  /// 08:05
  static String time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// 1 234 500 UZS
  static String money(int amount) {
    final s = amount.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${amount < 0 ? '-' : ''}${buf.toString()} UZS';
  }

  /// "Mon–Fri" for {1..5}, otherwise "Mon, Wed, Fri".
  static String weekdays(Set<int> days) {
    final sorted = days.toList()..sort();
    if (sorted.length == 5 && sorted.first == 1 && sorted.last == 5) return 'Mon–Fri';
    if (sorted.length == 7) return 'Every day';
    return sorted.map(weekday).join(', ');
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
