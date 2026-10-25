import 'package:flutter/foundation.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../utils/format.dart';
import 'auth_service.dart';
import 'compliance_service.dart';
import 'invoice_service.dart';

/// One line in the "Recent activity" feed on the dashboard.
class ActivityItem {
  final DateTime time;
  final String text;
  const ActivityItem(this.time, this.text);
}

/// Result of assigning a driver: always succeeds, but may carry a warning.
class AssignResult {
  final String message;
  final String? warning;
  const AssignResult(this.message, [this.warning]);
}

/// The single source of truth for the prototype.
///
/// All data lives in memory (seeded from [MockData]). Screens read from this
/// class with `context.watch<AppState>()` and call its methods to change
/// data. In the final app these methods will call the backend API instead.
class AppState extends ChangeNotifier {
  AppState({DateTime? today}) : today = Fmt.dateOnly(today ?? DateTime.now()) {
    _routes = MockData.routes(this.today);
    _bookings = MockData.bookings(this.today, _routes);
    _hours = MockData.hours(this.today);
    license = MockData.license(this.today);
    _nextBookingId = _bookings.length + 1;
  }

  final DateTime today;
  final AuthService auth = AuthService();

  late List<ShuttleRoute> _routes;
  late List<Booking> _bookings;
  late List<HoursEntry> _hours;
  late TransportLicense license;
  final List<Invoice> _invoices = [];
  final List<NotificationRecord> _notifications = [];
  final List<ActivityItem> _activity = [];

  /// Booking ids that were cancelled in this session -> time they were freed.
  /// Used to show "seat available again" (FR-03).
  final Map<String, DateTime> releasedSeats = {};

  int _nextBookingId = 1;
  int _nextRouteId = 100;

  // ---------------------------------------------------------------- getters
  List<ShuttleRoute> get routes => List.unmodifiable(_routes);
  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<HoursEntry> get hours => List.unmodifiable(_hours);
  List<Invoice> get invoices => List.unmodifiable(_invoices.reversed);
  List<NotificationRecord> get notifications => List.unmodifiable(_notifications.reversed);
  List<ActivityItem> get activity => List.unmodifiable(_activity.reversed);
  List<Employee> get employees => MockData.employees;
  List<Driver> get drivers => MockData.drivers;

  /// Today if shuttles run today, otherwise the next working day.
  /// (So the demo still shows data when presented on a weekend.)
  DateTime get serviceDay {
    var d = today;
    while (d.weekday > 5) {
      d = DateTime(d.year, d.month, d.day + 1);
    }
    return d;
  }

  bool get serviceDayIsToday => Fmt.sameDay(serviceDay, today);

  // ------------------------------------------------------------------- auth
  String? login(String email, String password) {
    final error = auth.login(email, password);
    if (error == null) _log('Signed in as ${auth.currentUser}');
    notifyListeners();
    return error;
  }

  void logout() {
    auth.logout();
    notifyListeners();
  }

  // ---------------------------------------------------------------- lookups
  ShuttleRoute? routeById(String id) {
    for (final r in _routes) {
      if (r.id == id) return r;
    }
    return null;
  }

  Employee employeeById(String id) => employees.firstWhere((e) => e.id == id);

  Driver? driverById(String? id) {
    if (id == null) return null;
    for (final d in drivers) {
      if (d.id == id) return d;
    }
    return null;
  }

  Stop? stopById(ShuttleRoute route, String stopId) {
    for (final s in route.stops) {
      if (s.id == stopId) return s;
    }
    return null;
  }

  // ------------------------------------------------------------ routes FR-01
  ShuttleRoute addRoute({
    required String name,
    required List<Stop> stops,
    required Set<int> weekdays,
    required DateTime startDate,
    required DateTime endDate,
    required int capacity,
    required int pricePerSeat,
  }) {
    final id = 'r${_nextRouteId++}';
    final route = ShuttleRoute(
      id: id,
      name: name,
      stops: [
        for (var i = 0; i < stops.length; i++)
          Stop(
            id: '${id}s${i + 1}',
            name: stops[i].name,
            time: stops[i].time,
            lat: stops[i].lat,
            lng: stops[i].lng,
          ),
      ],
      weekdays: weekdays,
      startDate: startDate,
      endDate: endDate,
      capacity: capacity,
      pricePerSeat: pricePerSeat,
    );
    _routes.add(route);
    _log('Route created: $name (${stops.length} stops)');
    notifyListeners();
    return route;
  }

  void deleteRoute(String routeId) {
    final route = routeById(routeId);
    if (route == null) return;
    _routes.removeWhere((r) => r.id == routeId);
    _bookings.removeWhere((b) => b.routeId == routeId);
    _log('Route deleted: ${route.name}');
    notifyListeners();
  }

  // ----------------------------------------------------------- seats FR-02/03
  List<Booking> activeBookings(String routeId, DateTime date) => _bookings
      .where((b) => b.isActive && b.routeId == routeId && Fmt.sameDay(b.date, date))
      .toList();

  int seatsTaken(String routeId, DateTime date) => activeBookings(routeId, date).length;

  int seatsLeft(String routeId, DateTime date) {
    final route = routeById(routeId);
    if (route == null) return 0;
    return route.capacity - seatsTaken(routeId, date);
  }

  /// Lowest free seat number on a route/date, or null if full.
  int? firstFreeSeat(String routeId, DateTime date, {String? exceptBookingId}) {
    final route = routeById(routeId);
    if (route == null) return null;
    final taken = activeBookings(routeId, date)
        .where((b) => b.id != exceptBookingId)
        .map((b) => b.seatNumber)
        .toSet();
    for (var n = 1; n <= route.capacity; n++) {
      if (!taken.contains(n)) return n;
    }
    return null;
  }

  /// Time a seat was freed by a cancellation in this session (FR-03), if the
  /// seat is still free. Used to highlight "available again" on the seat map.
  DateTime? seatReleasedAt(String routeId, DateTime date, int seatNumber) {
    final stillFree = activeBookings(routeId, date).every((b) => b.seatNumber != seatNumber);
    if (!stillFree) return null;
    DateTime? latest;
    for (final b in _bookings) {
      if (b.routeId == routeId && Fmt.sameDay(b.date, date) && b.seatNumber == seatNumber) {
        final t = releasedSeats[b.id];
        if (t != null && (latest == null || t.isAfter(latest))) latest = t;
      }
    }
    return latest;
  }

  Booking? _activeBookingFor(String employeeId, DateTime date, {String? exceptId}) {
    for (final b in _bookings) {
      if (b.isActive && b.employeeId == employeeId && Fmt.sameDay(b.date, date) && b.id != exceptId) {
        return b;
      }
    }
    return null;
  }

  /// Books a seat. Returns null on success or an error message.
  String? bookSeat({
    required String routeId,
    required String employeeId,
    required String stopId,
    required DateTime date,
    int? seatNumber,
  }) {
    final route = routeById(routeId);
    if (route == null) return 'Route not found.';
    if (!route.runsOn(date)) return '${route.name} does not run on ${Fmt.shortDate(date)}.';
    if (seatsLeft(routeId, date) <= 0) return 'No seats left on this shuttle.';

    final existing = _activeBookingFor(employeeId, date);
    if (existing != null) {
      final other = routeById(existing.routeId);
      return '${employeeById(employeeId).name} already has a seat on ${other?.name ?? 'another route'} that day.';
    }

    var seat = seatNumber;
    if (seat == null || activeBookings(routeId, date).any((b) => b.seatNumber == seat)) {
      seat = firstFreeSeat(routeId, date);
    }
    if (seat == null) return 'No seats left on this shuttle.';

    _bookings.add(Booking(
      id: 'b${_nextBookingId++}',
      routeId: routeId,
      employeeId: employeeId,
      stopId: stopId,
      seatNumber: seat,
      date: Fmt.dateOnly(date),
      status: BookingStatus.active,
      createdAt: DateTime.now(),
    ));
    _log('Seat booked: ${employeeById(employeeId).name} → ${route.name}, ${Fmt.shortDate(date)}');
    notifyListeners();
    return null;
  }

  /// Changes the stop and/or date of a booking. Returns null or an error.
  String? changeBooking(String bookingId, {String? stopId, DateTime? date}) {
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i < 0) return 'Booking not found.';
    final b = _bookings[i];
    final route = routeById(b.routeId)!;
    final newDate = date == null ? b.date : Fmt.dateOnly(date);

    if (!Fmt.sameDay(newDate, b.date)) {
      if (!route.runsOn(newDate)) return '${route.name} does not run on ${Fmt.shortDate(newDate)}.';
      if (seatsLeft(route.id, newDate) <= 0) return 'No seats left on ${Fmt.shortDate(newDate)}.';
      if (_activeBookingFor(b.employeeId, newDate, exceptId: b.id) != null) {
        return '${employeeById(b.employeeId).name} already has a seat that day.';
      }
    }

    var seat = b.seatNumber;
    if (!Fmt.sameDay(newDate, b.date)) {
      seat = firstFreeSeat(route.id, newDate) ?? b.seatNumber;
    }
    _bookings[i] = b.copyWith(stopId: stopId, date: newDate, seatNumber: seat);
    _log('Booking changed: ${employeeById(b.employeeId).name} (${Fmt.shortDate(newDate)})');
    notifyListeners();
    return null;
  }

  /// Cancels a booking. The seat is freed immediately - well within the
  /// 60 seconds required by FR-03.
  void cancelBooking(String bookingId) {
    final i = _bookings.indexWhere((b) => b.id == bookingId);
    if (i < 0) return;
    final b = _bookings[i];
    final now = DateTime.now();
    _bookings[i] = b.copyWith(status: BookingStatus.cancelled, cancelledAt: now);
    releasedSeats[b.id] = now;
    _log('Seat cancelled & released: ${employeeById(b.employeeId).name} (${routeById(b.routeId)?.name})');
    notifyListeners();
  }

  // ---------------------------------------------------------- drivers FR-04
  List<ShuttleRoute> routesForDriver(String driverId) =>
      _routes.where((r) => r.driverId == driverId).toList();

  /// Assigns or switches the driver of a route. Warns (but does not block)
  /// if the driver is over the legal hours this week (NFR-03).
  AssignResult assignDriver(String routeId, String driverId) {
    final i = _routes.indexWhere((r) => r.id == routeId);
    final route = _routes[i];
    final previous = driverById(route.driverId);
    final driver = driverById(driverId)!;

    _routes[i] = route.copyWith(driverId: driverId);

    final message = previous == null
        ? '${driver.name} assigned to ${route.name}'
        : 'Driver switched on ${route.name}: ${previous.name} → ${driver.name}';
    _log(message);

    String? warning;
    final monday = ComplianceService.weekStart(today);
    if (!ComplianceService.isCompliant(_hours, driverId, monday)) {
      warning = '${driver.name} is over the legal working-time limit this week. '
          'Check the Driver Hours log before the trip.';
    }
    final otherRoutes = routesForDriver(driverId).where((r) => r.id != routeId).toList();
    if (otherRoutes.isNotEmpty) {
      final clash = 'Also assigned to ${otherRoutes.map((r) => r.name).join(', ')} at a similar time.';
      warning = warning == null ? clash : '$warning\n$clash';
    }

    notifyListeners();
    return AssignResult(message, warning);
  }

  void unassignDriver(String routeId) {
    final i = _routes.indexWhere((r) => r.id == routeId);
    final route = _routes[i];
    _routes[i] = route.copyWith(clearDriver: true);
    _log('Driver removed from ${route.name}');
    notifyListeners();
  }

  // ------------------------------------------------------------ hours FR-07
  void logHours({
    required String driverId,
    required DateTime date,
    required double hoursWorked,
    required double restHours,
  }) {
    final d = Fmt.dateOnly(date);
    _hours.removeWhere((e) => e.driverId == driverId && Fmt.sameDay(e.date, d));
    _hours.add(HoursEntry(driverId: driverId, date: d, hoursWorked: hoursWorked, restHours: restHours));
    _log('Hours logged: ${driverById(driverId)?.name}, ${Fmt.shortDate(d)} – ${hoursWorked.toStringAsFixed(1)} h');
    notifyListeners();
  }

  int nonCompliantDriverCount() {
    final monday = ComplianceService.weekStart(today);
    return drivers.where((d) => !ComplianceService.isCompliant(_hours, d.id, monday)).length;
  }

  // ---------------------------------------------------------- invoice FR-06
  Invoice generateInvoice(DateTime start, DateTime end) {
    final n = _invoices.length + 1;
    final invoice = InvoiceService.generate(
      id: 'inv$n',
      number: 'RL-${today.year}${today.month.toString().padLeft(2, '0')}-${n.toString().padLeft(3, '0')}',
      start: start,
      end: end,
      bookings: _bookings,
      routes: _routes,
    );
    _invoices.add(invoice);
    _log('Invoice ${invoice.number} generated: ${Fmt.money(invoice.total)}');
    notifyListeners();
    return invoice;
  }

  // ------------------------------------------------------ notifications FR-08
  void addNotifications(List<NotificationRecord> records) {
    if (records.isEmpty) return;
    _notifications.addAll(records);
    _log('Arrival alert sent to ${records.length ~/ 2} rider(s) (SMS + email, simulated)');
    notifyListeners();
  }

  /// Employees with an active booking at [stopId] on the service day.
  List<Employee> ridersAtStop(String routeId, String stopId) => activeBookings(routeId, serviceDay)
      .where((b) => b.stopId == stopId)
      .map((b) => employeeById(b.employeeId))
      .toList();

  // --------------------------------------------------------------- dashboard
  List<ShuttleRoute> get serviceDayRoutes => _routes.where((r) => r.runsOn(serviceDay)).toList()
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

  int get openSeatsOnServiceDay =>
      serviceDayRoutes.fold(0, (sum, r) => sum + seatsLeft(r.id, serviceDay));

  int get ridersOnServiceDay =>
      serviceDayRoutes.fold(0, (sum, r) => sum + seatsTaken(r.id, serviceDay));

  int get unassignedRoutes => _routes.where((r) => r.driverId == null).length;

  // ----------------------------------------------------------------- private
  void _log(String text) => _activity.add(ActivityItem(DateTime.now(), text));
}
