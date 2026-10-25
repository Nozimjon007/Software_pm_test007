import 'package:flutter_test/flutter_test.dart';
import 'package:rideline/models/models.dart';
import 'package:rideline/services/notification_service.dart';
import 'package:rideline/services/tracking_simulator.dart';

void main() {
  final route = ShuttleRoute(
    id: 'r',
    name: 'Test route',
    stops: const [
      Stop(id: 's1', name: 'A', time: '08:00', lat: 41.0, lng: 69.0),
      Stop(id: 's2', name: 'B', time: '08:10', lat: 41.1, lng: 69.1),
      Stop(id: 's3', name: 'C', time: '08:30', lat: 41.2, lng: 69.2),
    ],
    weekdays: const {1, 2, 3, 4, 5},
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
    capacity: 10,
    pricePerSeat: 10000,
  );

  group('Live tracking simulator', () {
    test('starts at the first stop', () {
      final sim = TrackingSimulator(route);
      expect(sim.position, (41.0, 69.0));
      expect(sim.nextStopIndex, 1);
      expect(sim.totalMinutes, 30);
    });

    test('moves between stops', () {
      final sim = TrackingSimulator(route)..tick(5); // halfway A -> B
      final (lat, lng) = sim.position;
      expect(lat, closeTo(41.05, 1e-9));
      expect(lng, closeTo(69.05, 1e-9));
      expect(sim.etaMinutes(1), 5);
    });

    test('finishes at the last stop', () {
      final sim = TrackingSimulator(route)..tick(100);
      expect(sim.finished, isTrue);
      expect(sim.position, (41.2, 69.2));
      expect(sim.nextStopIndex, 3);
    });
  });

  group('FR-08 notifications (simulated)', () {
    test('one SMS and one email per rider', () {
      const e = Employee(id: 'e', name: 'Test Rider', department: 'IT', phone: '+998', email: 't@x.uz');
      final records = NotificationService.notifyRiders(
        riders: [e],
        route: route,
        stop: route.stops[1],
        etaMinutes: 10,
      );
      expect(records.length, 2);
      expect(records.first.channel, NotificationChannel.sms);
      expect(records.first.message, contains('10 min'));
    });
  });

  group('NFR-04 license warning', () {
    final license = TransportLicense(
      number: 'X',
      issuedBy: 'Y',
      issuedOn: DateTime(2024, 1, 1),
      expiresOn: DateTime(2026, 11, 15),
    );

    test('no warning when far from expiry', () {
      expect(license.needsWarning(DateTime(2026, 9, 1)), isFalse);
    });

    test('warning within 30 days', () {
      expect(license.daysLeft(DateTime(2026, 10, 25)), 21);
      expect(license.needsWarning(DateTime(2026, 10, 25)), isTrue);
      expect(license.isExpired(DateTime(2026, 10, 25)), isFalse);
    });

    test('expired after the date', () {
      expect(license.isExpired(DateTime(2026, 11, 16)), isTrue);
    });
  });
}
