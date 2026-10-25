import 'stop.dart';

/// A shuttle route created and managed by the organizer (FR-01).
///
/// Named `ShuttleRoute` (not `Route`) so it does not clash with Flutter's
/// navigation `Route` class.
class ShuttleRoute {
  final String id;
  final String name;
  final List<Stop> stops;

  /// Weekdays the route runs: 1 = Monday ... 7 = Sunday.
  final Set<int> weekdays;
  final DateTime startDate;
  final DateTime endDate;

  /// Number of seats in the shuttle.
  final int capacity;

  /// Price charged per booked seat per trip, in UZS (used by FR-06).
  final int pricePerSeat;

  /// Currently assigned driver (FR-04). Null = no driver yet.
  final String? driverId;

  const ShuttleRoute({
    required this.id,
    required this.name,
    required this.stops,
    required this.weekdays,
    required this.startDate,
    required this.endDate,
    required this.capacity,
    required this.pricePerSeat,
    this.driverId,
  });

  String get departureTime => stops.isEmpty ? '--:--' : stops.first.time;
  String get arrivalTime => stops.isEmpty ? '--:--' : stops.last.time;

  /// True if the route runs on the given calendar day.
  bool runsOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (d.isBefore(start) || d.isAfter(end)) return false;
    return weekdays.contains(d.weekday);
  }

  ShuttleRoute copyWith({
    String? name,
    List<Stop>? stops,
    Set<int>? weekdays,
    DateTime? startDate,
    DateTime? endDate,
    int? capacity,
    int? pricePerSeat,
    String? driverId,
    bool clearDriver = false,
  }) {
    return ShuttleRoute(
      id: id,
      name: name ?? this.name,
      stops: stops ?? this.stops,
      weekdays: weekdays ?? this.weekdays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      capacity: capacity ?? this.capacity,
      pricePerSeat: pricePerSeat ?? this.pricePerSeat,
      driverId: clearDriver ? null : (driverId ?? this.driverId),
    );
  }
}
