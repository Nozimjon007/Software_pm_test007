import '../models/hours_entry.dart';

/// Kind of rule a driver broke.
enum ViolationType { dailyHours, weeklyHours, shortRest }

class ComplianceViolation {
  final ViolationType type;
  final DateTime date;
  final String message;

  const ComplianceViolation(this.type, this.date, this.message);
}

/// Checks driver working time against legal limits (FR-07, NFR-03).
///
/// Limits are based on Uzbekistan's rules on driver working and rest time
/// (lex.uz/docs/-2234877) and the Labour Code 40-hour week. They are kept as
/// constants in one place so QA / the PM can adjust them after checking the
/// regulation, without touching the screens.
class ComplianceService {
  ComplianceService._();

  /// Maximum working time in one day (hours).
  static const double maxDailyHours = 10;

  /// Maximum normal working time in one week (hours).
  static const double maxWeeklyHours = 40;

  /// Minimum rest between two shifts (hours).
  static const double minRestHours = 12;

  /// Monday of the week that contains [day].
  static DateTime weekStart(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  /// Sum of hours for one driver in the week starting [monday].
  static double weeklyHours(List<HoursEntry> entries, String driverId, DateTime monday) {
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    return entries
        .where((e) => e.driverId == driverId)
        .where((e) => !e.date.isBefore(monday) && !e.date.isAfter(sunday))
        .fold(0.0, (sum, e) => sum + e.hoursWorked);
  }

  /// All violations for one driver in the week starting [monday].
  static List<ComplianceViolation> violations(
    List<HoursEntry> entries,
    String driverId,
    DateTime monday,
  ) {
    final sunday = DateTime(monday.year, monday.month, monday.day + 6);
    final week = entries
        .where((e) => e.driverId == driverId)
        .where((e) => !e.date.isBefore(monday) && !e.date.isAfter(sunday))
        .toList();

    final result = <ComplianceViolation>[];
    for (final e in week) {
      if (e.hoursWorked > maxDailyHours) {
        result.add(ComplianceViolation(
          ViolationType.dailyHours,
          e.date,
          'Worked ${e.hoursWorked.toStringAsFixed(1)} h (limit ${maxDailyHours.toStringAsFixed(0)} h/day)',
        ));
      }
      if (e.restHours < minRestHours) {
        result.add(ComplianceViolation(
          ViolationType.shortRest,
          e.date,
          'Rest only ${e.restHours.toStringAsFixed(1)} h (minimum ${minRestHours.toStringAsFixed(0)} h)',
        ));
      }
    }

    final total = week.fold(0.0, (sum, e) => sum + e.hoursWorked);
    if (total > maxWeeklyHours) {
      result.add(ComplianceViolation(
        ViolationType.weeklyHours,
        monday,
        'Week total ${total.toStringAsFixed(1)} h (limit ${maxWeeklyHours.toStringAsFixed(0)} h/week)',
      ));
    }
    return result;
  }

  static bool isCompliant(List<HoursEntry> entries, String driverId, DateTime monday) =>
      violations(entries, driverId, monday).isEmpty;
}
