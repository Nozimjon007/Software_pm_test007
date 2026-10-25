/// One day of work for a driver, used for the compliance log (FR-07, NFR-03).
class HoursEntry {
  final String driverId;
  final DateTime date;

  /// Total working time that day, in hours.
  final double hoursWorked;

  /// Rest time between this shift and the next one, in hours.
  final double restHours;

  const HoursEntry({
    required this.driverId,
    required this.date,
    required this.hoursWorked,
    required this.restHours,
  });
}
