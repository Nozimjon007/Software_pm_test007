/// A pickup / drop-off point on a shuttle route (FR-01).
class Stop {
  final String id;
  final String name;

  /// Scheduled time at this stop, 24h format "HH:mm".
  final String time;
  final double lat;
  final double lng;

  const Stop({
    required this.id,
    required this.name,
    required this.time,
    required this.lat,
    required this.lng,
  });

  /// Minutes since midnight, e.g. "08:15" -> 495.
  int get minutesOfDay {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  Stop copyWith({String? name, String? time, double? lat, double? lng}) {
    return Stop(
      id: id,
      name: name ?? this.name,
      time: time ?? this.time,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}
