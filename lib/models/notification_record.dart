enum NotificationChannel { sms, email }

/// A rider notification (FR-08). In the prototype these are simulated:
/// nothing is really sent, the record is shown on screen instead.
class NotificationRecord {
  final DateTime sentAt;
  final String employeeName;
  final String destination; // phone number or email
  final NotificationChannel channel;
  final String message;

  const NotificationRecord({
    required this.sentAt,
    required this.employeeName,
    required this.destination,
    required this.channel,
    required this.message,
  });
}
