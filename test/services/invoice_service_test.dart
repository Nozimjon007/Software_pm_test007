import 'package:flutter_test/flutter_test.dart';
import 'package:rideline/models/models.dart';
import 'package:rideline/services/invoice_service.dart';

/// FR-06: invoice generated from bookings.
void main() {
  final route = ShuttleRoute(
    id: 'r',
    name: 'Test route',
    stops: const [
      Stop(id: 's1', name: 'A', time: '08:00', lat: 41.3, lng: 69.2),
      Stop(id: 's2', name: 'B', time: '08:20', lat: 41.31, lng: 69.25),
    ],
    weekdays: const {1, 2, 3, 4, 5},
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 31),
    capacity: 10,
    pricePerSeat: 10000,
  );

  Booking b(String id, int day, {bool cancelled = false}) => Booking(
        id: id,
        routeId: 'r',
        employeeId: 'e$id',
        stopId: 's1',
        seatNumber: 1,
        date: DateTime(2026, 10, day),
        status: cancelled ? BookingStatus.cancelled : BookingStatus.active,
        createdAt: DateTime(2026, 10, 1),
      );

  test('bills active bookings inside the period only', () {
    final bookings = [
      b('1', 5),
      b('2', 6),
      b('3', 7, cancelled: true), // not billed
      b('4', 30), // outside the period
    ];

    final inv = InvoiceService.generate(
      id: 'i1',
      number: 'RL-TEST-001',
      start: DateTime(2026, 10, 1),
      end: DateTime(2026, 10, 15),
      bookings: bookings,
      routes: [route],
    );

    expect(inv.totalSeats, 2);
    expect(inv.subtotal, 20000);
    expect(inv.vat, 2400); // 12 %
    expect(inv.total, 22400);
  });

  test('empty period gives an invoice with no lines', () {
    final inv = InvoiceService.generate(
      id: 'i2',
      number: 'RL-TEST-002',
      start: DateTime(2026, 11, 1),
      end: DateTime(2026, 11, 30),
      bookings: [b('1', 5)],
      routes: [route],
    );
    expect(inv.lines, isEmpty);
    expect(inv.total, 0);
  });
}
