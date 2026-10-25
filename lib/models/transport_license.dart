/// The organization's passenger-transport license (NFR-04).
class TransportLicense {
  final String number;
  final String issuedBy;
  final DateTime issuedOn;
  final DateTime expiresOn;

  /// Warn the organizer this many days before expiry.
  static const int warningDays = 30;

  const TransportLicense({
    required this.number,
    required this.issuedBy,
    required this.issuedOn,
    required this.expiresOn,
  });

  int daysLeft(DateTime today) {
    final t = DateTime(today.year, today.month, today.day);
    final e = DateTime(expiresOn.year, expiresOn.month, expiresOn.day);
    return e.difference(t).inDays;
  }

  bool isExpired(DateTime today) => daysLeft(today) < 0;
  bool needsWarning(DateTime today) => daysLeft(today) <= warningDays;
}
