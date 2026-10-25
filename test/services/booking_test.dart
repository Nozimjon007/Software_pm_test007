import 'package:flutter_test/flutter_test.dart';
import 'package:rideline/services/app_state.dart';

/// FR-02 (book / change / cancel) and FR-03 (cancelled seat is freed).
void main() {
  // Wednesday, so shuttles run that day.
  final today = DateTime(2026, 10, 21);
  late AppState state;

  setUp(() => state = AppState(today: today));

  test('seed data has open seats on route r1', () {
    expect(state.seatsTaken('r1', today), 6);
    expect(state.seatsLeft('r1', today), 6);
  });

  test('FR-02: organizer can book a seat for an employee', () {
    final error = state.bookSeat(routeId: 'r1', employeeId: 'e14', stopId: 'r1s1', date: today);
    expect(error, isNull);
    expect(state.seatsTaken('r1', today), 7);
  });

  test('FR-02: the same employee cannot be booked twice on one day', () {
    state.bookSeat(routeId: 'r1', employeeId: 'e14', stopId: 'r1s1', date: today);
    final error = state.bookSeat(routeId: 'r2', employeeId: 'e14', stopId: 'r2s1', date: today);
    expect(error, isNotNull);
  });

  test('FR-02: booking a full shuttle is refused', () {
    // r3 has 10 seats and 3 regular riders -> fill the other 7.
    for (final id in ['e1', 'e2', 'e3', 'e4', 'e5', 'e6', 'e7']) {
      state.cancelBooking(
        state.bookings.firstWhere((b) => b.isActive && b.employeeId == id && b.date == today).id,
      );
      expect(state.bookSeat(routeId: 'r3', employeeId: id, stopId: 'r3s1', date: today), isNull);
    }
    expect(state.seatsLeft('r3', today), 0);
    final error = state.bookSeat(routeId: 'r3', employeeId: 'e14', stopId: 'r3s1', date: today);
    expect(error, 'No seats left on this shuttle.');
  });

  test('FR-02: organizer can change the stop of a booking', () {
    final b = state.activeBookings('r1', today).first;
    final error = state.changeBooking(b.id, stopId: 'r1s3');
    expect(error, isNull);
    expect(state.bookings.firstWhere((x) => x.id == b.id).stopId, 'r1s3');
  });

  test('FR-03: a cancelled seat is available again immediately (< 60 s)', () {
    final before = state.seatsLeft('r1', today);
    final b = state.activeBookings('r1', today).first;

    final started = DateTime.now();
    state.cancelBooking(b.id);
    final elapsed = DateTime.now().difference(started);

    expect(state.seatsLeft('r1', today), before + 1);
    expect(elapsed.inSeconds, lessThan(60));
    expect(state.releasedSeats.containsKey(b.id), isTrue);
    expect(state.seatReleasedAt('r1', today, b.seatNumber), isNotNull);

    // Someone else can now take that exact seat.
    final error = state.bookSeat(
      routeId: 'r1',
      employeeId: 'e14',
      stopId: 'r1s1',
      date: today,
      seatNumber: b.seatNumber,
    );
    expect(error, isNull);
    expect(state.activeBookings('r1', today).any((x) => x.seatNumber == b.seatNumber && x.employeeId == 'e14'), isTrue);
  });

  test('FR-01: organizer can create a route', () {
    final count = state.routes.length;
    final r = state.addRoute(
      name: 'Test route',
      stops: state.routes.first.stops,
      weekdays: {1, 3, 5},
      startDate: today,
      endDate: today.add(const Duration(days: 30)),
      capacity: 8,
      pricePerSeat: 10000,
    );
    expect(state.routes.length, count + 1);
    expect(r.stops.length, 4);
    expect(r.runsOn(today), isTrue); // Wednesday
  });

  test('FR-04: organizer can assign and switch a driver', () {
    expect(state.routeById('r3')!.driverId, isNull);
    state.assignDriver('r3', 'd4');
    expect(state.routeById('r3')!.driverId, 'd4');
    final result = state.assignDriver('r3', 'd2');
    expect(state.routeById('r3')!.driverId, 'd2');
    expect(result.message, contains('switched'));
  });

  test('FR-04: assigning an over-limit driver gives a warning', () {
    final result = state.assignDriver('r3', 'd1'); // Bekzod is over the limit in seed data
    expect(result.warning, isNotNull);
  });
}
