import '../models/models.dart';

/// A named location with coordinates.
class Place {
  final String name;
  final double lat;
  final double lng;
  const Place(this.name, this.lat, this.lng);
}

/// Sample data for the prototype.
///
/// Everything is generated relative to "today" so the demo always looks fresh
/// (bookings this month, hours for the last two weeks, a license that expires
/// soon). No real people or companies - all names are fictional.
class MockData {
  MockData._();

  // ----------------------------------------------------------------- places
  /// Known pickup points in Tashkent the organizer can choose from when
  /// creating a route (so every stop has map coordinates).
  static const List<Place> places = [
    Place('Tashkent City Office', 41.3150, 69.2470),
    Place('Chilonzor metro', 41.2753, 69.2040),
    Place("Mirzo Ulug'bek metro", 41.2826, 69.2133),
    Place('Bunyodkor avenue', 41.2967, 69.2299),
    Place('Yunusobod bazaar', 41.3640, 69.2870),
    Place('Minor metro', 41.3290, 69.2850),
    Place('Amir Temur square', 41.3111, 69.2797),
    Place('Sergeli 5-mavze', 41.2230, 69.2190),
    Place('Olmazor', 41.2510, 69.2140),
    Place('Novza metro', 41.2925, 69.2241),
    Place('Chorsu bazaar', 41.3262, 69.2353),
    Place('Beruniy metro', 41.3449, 69.2059),
    Place('Oybek metro', 41.2990, 69.2770),
    Place('Mustaqillik square', 41.3090, 69.2700),
    Place("Buyuk Ipak Yo'li metro", 41.3260, 69.3330),
    Place('Qoraqamish', 41.3530, 69.2160),
  ];

  // ---------------------------------------------------------------- drivers
  static const List<Driver> drivers = [
    Driver(
      id: 'd1',
      name: 'Bekzod Karimov',
      phone: '+998 90 111 22 33',
      licenseNumber: 'AA 1234567',
      vehicle: 'Isuzu Bogdan · 01 A 123 BA',
    ),
    Driver(
      id: 'd2',
      name: 'Sherzod Aliyev',
      phone: '+998 91 222 33 44',
      licenseNumber: 'AB 2345678',
      vehicle: 'Mercedes Sprinter · 01 B 456 CA',
    ),
    Driver(
      id: 'd3',
      name: 'Akmal Rakhimov',
      phone: '+998 93 333 44 55',
      licenseNumber: 'AC 3456789',
      vehicle: 'Isuzu Bogdan · 01 C 789 DA',
    ),
    Driver(
      id: 'd4',
      name: 'Jasur Tursunov',
      phone: '+998 94 444 55 66',
      licenseNumber: 'AD 4567890',
      vehicle: 'Hyundai County · 01 D 012 EA',
    ),
  ];

  // -------------------------------------------------------------- employees
  static const List<Employee> employees = [
    Employee(id: 'e1', name: 'Dilnoza Yusupova', department: 'HR', phone: '+998 90 100 00 01', email: 'dilnoza@example.uz'),
    Employee(id: 'e2', name: 'Otabek Nazarov', department: 'Finance', phone: '+998 90 100 00 02', email: 'otabek@example.uz'),
    Employee(id: 'e3', name: 'Madina Ergasheva', department: 'IT', phone: '+998 90 100 00 03', email: 'madina@example.uz'),
    Employee(id: 'e4', name: 'Rustam Saidov', department: 'Sales', phone: '+998 90 100 00 04', email: 'rustam@example.uz'),
    Employee(id: 'e5', name: 'Nigora Abdullayeva', department: 'Marketing', phone: '+998 90 100 00 05', email: 'nigora@example.uz'),
    Employee(id: 'e6', name: 'Sardor Islomov', department: 'IT', phone: '+998 90 100 00 06', email: 'sardor@example.uz'),
    Employee(id: 'e7', name: 'Kamola Raximova', department: 'Legal', phone: '+998 90 100 00 07', email: 'kamola@example.uz'),
    Employee(id: 'e8', name: 'Aziz Qodirov', department: 'Operations', phone: '+998 90 100 00 08', email: 'aziz@example.uz'),
    Employee(id: 'e9', name: 'Shahzoda Mirzayeva', department: 'HR', phone: '+998 90 100 00 09', email: 'shahzoda@example.uz'),
    Employee(id: 'e10', name: 'Jamshid Usmonov', department: 'Finance', phone: '+998 90 100 00 10', email: 'jamshid@example.uz'),
    Employee(id: 'e11', name: 'Malika Xolmatova', department: 'Support', phone: '+998 90 100 00 11', email: 'malika@example.uz'),
    Employee(id: 'e12', name: 'Bobur Tojiboyev', department: 'Operations', phone: '+998 90 100 00 12', email: 'bobur@example.uz'),
    Employee(id: 'e13', name: 'Zarina Hasanova', department: 'Design', phone: '+998 90 100 00 13', email: 'zarina@example.uz'),
    Employee(id: 'e14', name: 'Ulugbek Sobirov', department: 'Sales', phone: '+998 90 100 00 14', email: 'ulugbek@example.uz'),
  ];

  // ----------------------------------------------------------------- routes
  static List<ShuttleRoute> routes(DateTime today) {
    final start = DateTime(today.year, today.month - 1, 1);
    final end = DateTime(today.year, today.month + 6, 0);
    const weekdays = {1, 2, 3, 4, 5};

    return [
      ShuttleRoute(
        id: 'r1',
        name: 'Chilonzor → Tashkent City Office',
        weekdays: weekdays,
        startDate: start,
        endDate: end,
        capacity: 12,
        pricePerSeat: 12000,
        driverId: 'd1',
        stops: const [
          Stop(id: 'r1s1', name: 'Chilonzor metro', time: '07:45', lat: 41.2753, lng: 69.2040),
          Stop(id: 'r1s2', name: "Mirzo Ulug'bek metro", time: '07:55', lat: 41.2826, lng: 69.2133),
          Stop(id: 'r1s3', name: 'Bunyodkor avenue', time: '08:05', lat: 41.2967, lng: 69.2299),
          Stop(id: 'r1s4', name: 'Tashkent City Office', time: '08:20', lat: 41.3150, lng: 69.2470),
        ],
      ),
      ShuttleRoute(
        id: 'r2',
        name: 'Yunusobod → Tashkent City Office',
        weekdays: weekdays,
        startDate: start,
        endDate: end,
        capacity: 14,
        pricePerSeat: 14000,
        driverId: 'd2',
        stops: const [
          Stop(id: 'r2s1', name: 'Yunusobod bazaar', time: '07:40', lat: 41.3640, lng: 69.2870),
          Stop(id: 'r2s2', name: 'Minor metro', time: '07:55', lat: 41.3290, lng: 69.2850),
          Stop(id: 'r2s3', name: 'Amir Temur square', time: '08:05', lat: 41.3111, lng: 69.2797),
          Stop(id: 'r2s4', name: 'Tashkent City Office', time: '08:20', lat: 41.3150, lng: 69.2470),
        ],
      ),
      ShuttleRoute(
        id: 'r3',
        name: 'Sergeli → Tashkent City Office',
        weekdays: weekdays,
        startDate: start,
        endDate: end,
        capacity: 10,
        pricePerSeat: 15000,
        driverId: null, // intentionally unassigned -> demo FR-04
        stops: const [
          Stop(id: 'r3s1', name: 'Sergeli 5-mavze', time: '07:30', lat: 41.2230, lng: 69.2190),
          Stop(id: 'r3s2', name: 'Olmazor', time: '07:45', lat: 41.2510, lng: 69.2140),
          Stop(id: 'r3s3', name: 'Novza metro', time: '07:58', lat: 41.2925, lng: 69.2241),
          Stop(id: 'r3s4', name: 'Tashkent City Office', time: '08:20', lat: 41.3150, lng: 69.2470),
        ],
      ),
    ];
  }

  /// Which employees ride which route by default (used to seed bookings).
  static const Map<String, List<String>> _regularRiders = {
    'r1': ['e1', 'e2', 'e3', 'e4', 'e5', 'e13'],
    'r2': ['e6', 'e7', 'e8', 'e9'],
    'r3': ['e10', 'e11', 'e12'],
  };

  // --------------------------------------------------------------- bookings
  /// Seeds bookings for every working day from the 1st of this month until
  /// two days from now, so the invoice and dashboard have real numbers.
  static List<Booking> bookings(DateTime today, List<ShuttleRoute> routes) {
    final result = <Booking>[];
    var counter = 1;
    final from = DateTime(today.year, today.month, 1);
    final to = DateTime(today.year, today.month, today.day + 2);

    for (var day = from; !day.isAfter(to); day = DateTime(day.year, day.month, day.day + 1)) {
      for (final route in routes) {
        if (!route.runsOn(day)) continue;
        final riders = _regularRiders[route.id] ?? const [];
        for (var i = 0; i < riders.length; i++) {
          final stop = route.stops[i % (route.stops.length - 1)]; // never the office
          result.add(Booking(
            id: 'b${counter++}',
            routeId: route.id,
            employeeId: riders[i],
            stopId: stop.id,
            seatNumber: i + 1,
            date: day,
            status: BookingStatus.active,
            createdAt: day.subtract(const Duration(days: 1)),
          ));
        }
      }
    }
    return result;
  }

  // ------------------------------------------------------------ driver hours
  /// Last 14 days of hours. Bekzod (d1) goes over the daily and weekly limit,
  /// Akmal (d3) has one short rest period - so the warnings show in the demo.
  static List<HoursEntry> hours(DateTime today) {
    final result = <HoursEntry>[];
    for (var back = 13; back >= 0; back--) {
      final day = DateTime(today.year, today.month, today.day - back);
      if (day.weekday > 5) continue; // shuttles run Mon-Fri

      for (final d in drivers) {
        double worked = 7.5;
        double rest = 16.5;

        if (d.id == 'd1') {
          // Overloaded driver: long days in the last week.
          if (back <= 6) worked = (back == 2) ? 11.5 : 9.0;
          rest = 24 - worked;
        } else if (d.id == 'd2') {
          worked = 8.0;
          rest = 16.0;
        } else if (d.id == 'd3') {
          worked = 7.0;
          rest = back == 3 ? 9.0 : 17.0; // short rest -> warning
        } else if (d.id == 'd4') {
          worked = 6.0;
          rest = 18.0;
        }

        result.add(HoursEntry(
          driverId: d.id,
          date: day,
          hoursWorked: worked,
          restHours: rest,
        ));
      }
    }
    return result;
  }

  // ---------------------------------------------------------------- license
  /// Expires in 21 days -> inside the 30-day warning window (NFR-04).
  static TransportLicense license(DateTime today) {
    return TransportLicense(
      number: 'UZ-PT-2024-00871',
      issuedBy: 'Ministry of Transport of the Republic of Uzbekistan',
      issuedOn: DateTime(today.year - 2, today.month, today.day + 21),
      expiresOn: DateTime(today.year, today.month, today.day + 21),
    );
  }
}
