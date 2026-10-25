enum BookingStatus { active, cancelled }

/// A seat booked by the organizer for an employee on a route and date (FR-02).
class Booking {
  final String id;
  final String routeId;
  final String employeeId;
  final String stopId;

  /// Seat number in the shuttle, 1..capacity.
  final int seatNumber;
  final DateTime date;
  final BookingStatus status;
  final DateTime createdAt;
  final DateTime? cancelledAt;

  const Booking({
    required this.id,
    required this.routeId,
    required this.employeeId,
    required this.stopId,
    required this.seatNumber,
    required this.date,
    required this.status,
    required this.createdAt,
    this.cancelledAt,
  });

  bool get isActive => status == BookingStatus.active;

  Booking copyWith({
    String? routeId,
    String? stopId,
    int? seatNumber,
    DateTime? date,
    BookingStatus? status,
    DateTime? cancelledAt,
  }) {
    return Booking(
      id: id,
      routeId: routeId ?? this.routeId,
      employeeId: employeeId,
      stopId: stopId ?? this.stopId,
      seatNumber: seatNumber ?? this.seatNumber,
      date: date ?? this.date,
      status: status ?? this.status,
      createdAt: createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
    );
  }
}
