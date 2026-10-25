/// An employee (rider). Riders do NOT log in - the organizer books for them.
/// They only receive a text/email before the shuttle arrives (FR-08).
class Employee {
  final String id;
  final String name;
  final String department;
  final String phone;
  final String email;

  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.phone,
    required this.email,
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }
}
