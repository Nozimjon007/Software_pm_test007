import '../models/models.dart';

/// Rider notifications (FR-08) - SIMULATED in the prototype.
///
/// Riders get a text or email ~10 minutes before the shuttle reaches their
/// stop. For the midterm we do not connect a real SMS gateway (e.g. Eskiz /
/// Play Mobile) or SMTP server; we build the message and show it on screen.
/// Nozimjon (DevOps) will plug in a real provider for the final version.
class NotificationService {
  NotificationService._();

  /// How many minutes before arrival riders are notified.
  static const int leadMinutes = 10;

  static String buildMessage({
    required Employee employee,
    required ShuttleRoute route,
    required Stop stop,
    required int etaMinutes,
  }) {
    final first = employee.name.split(' ').first;
    return 'Hi $first, your RideLine shuttle (${route.name}) '
        'arrives at ${stop.name} in about $etaMinutes min.';
  }

  /// Creates one SMS + one email record per employee. Nothing leaves the app.
  static List<NotificationRecord> notifyRiders({
    required List<Employee> riders,
    required ShuttleRoute route,
    required Stop stop,
    required int etaMinutes,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    final result = <NotificationRecord>[];
    for (final e in riders) {
      final msg = buildMessage(employee: e, route: route, stop: stop, etaMinutes: etaMinutes);
      result.add(NotificationRecord(
        sentAt: time,
        employeeName: e.name,
        destination: e.phone,
        channel: NotificationChannel.sms,
        message: msg,
      ));
      result.add(NotificationRecord(
        sentAt: time,
        employeeName: e.name,
        destination: e.email,
        channel: NotificationChannel.email,
        message: msg,
      ));
    }
    return result;
  }
}
