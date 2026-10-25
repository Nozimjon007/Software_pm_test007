/// One line of an invoice: all seats booked on one route in the period.
class InvoiceLine {
  final String routeName;
  final int seats;
  final int unitPrice;

  const InvoiceLine({
    required this.routeName,
    required this.seats,
    required this.unitPrice,
  });

  int get total => seats * unitPrice;
}

/// Invoice generated from bookings for a billing period (FR-06).
class Invoice {
  final String id;
  final String number;
  final DateTime periodStart;
  final DateTime periodEnd;
  final DateTime createdAt;
  final List<InvoiceLine> lines;

  /// VAT rate applied on top of the subtotal (Uzbekistan standard rate).
  static const double vatRate = 0.12;

  const Invoice({
    required this.id,
    required this.number,
    required this.periodStart,
    required this.periodEnd,
    required this.createdAt,
    required this.lines,
  });

  int get subtotal => lines.fold(0, (sum, l) => sum + l.total);
  int get vat => (subtotal * vatRate).round();
  int get total => subtotal + vat;
  int get totalSeats => lines.fold(0, (sum, l) => sum + l.seats);
}
