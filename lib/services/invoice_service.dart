import '../models/models.dart';

/// Builds invoices from bookings (FR-06).
///
/// In the final product this runs automatically at the end of each billing
/// period. In the prototype the organizer triggers it with a button.
class InvoiceService {
  InvoiceService._();

  /// Creates an invoice for all ACTIVE bookings between [start] and [end]
  /// (inclusive). Cancelled seats are not billed.
  static Invoice generate({
    required String id,
    required String number,
    required DateTime start,
    required DateTime end,
    required List<Booking> bookings,
    required List<ShuttleRoute> routes,
    DateTime? now,
  }) {
    final from = DateTime(start.year, start.month, start.day);
    final to = DateTime(end.year, end.month, end.day);

    final lines = <InvoiceLine>[];
    for (final route in routes) {
      final seats = bookings.where((b) {
        if (!b.isActive || b.routeId != route.id) return false;
        final d = DateTime(b.date.year, b.date.month, b.date.day);
        return !d.isBefore(from) && !d.isAfter(to);
      }).length;

      if (seats > 0) {
        lines.add(InvoiceLine(
          routeName: route.name,
          seats: seats,
          unitPrice: route.pricePerSeat,
        ));
      }
    }

    return Invoice(
      id: id,
      number: number,
      periodStart: from,
      periodEnd: to,
      createdAt: now ?? DateTime.now(),
      lines: lines,
    );
  }
}
