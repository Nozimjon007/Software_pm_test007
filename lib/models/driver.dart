/// A shuttle driver. Drivers do not have accounts in RideLine; the organizer
/// assigns them to routes (FR-04) and their hours are logged (FR-07).
class Driver {
  final String id;
  final String name;
  final String phone;
  final String licenseNumber;
  final String vehicle;

  const Driver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNumber,
    required this.vehicle,
  });
}
