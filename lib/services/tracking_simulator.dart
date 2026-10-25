import '../models/shuttle_route.dart';

/// Simulated GPS feed for the live tracking map.
///
/// There is no driver app, so we cannot get real GPS. Instead we move the
/// shuttle along the straight lines between stops, using the scheduled stop
/// times. Progress is measured in "route minutes" since the first stop.
///
/// This class has no Flutter dependency so it can be unit tested.
class TrackingSimulator {
  final ShuttleRoute route;

  /// Minutes since the first stop, for each stop (first is always 0).
  late final List<double> _offsets;

  double _progress = 0;

  TrackingSimulator(this.route) {
    final first = route.stops.first.minutesOfDay;
    _offsets = route.stops.map((s) => (s.minutesOfDay - first).toDouble()).toList();
  }

  /// Total route duration in minutes.
  double get totalMinutes => _offsets.last;

  double get progress => _progress;
  bool get finished => _progress >= totalMinutes;

  /// 0.0 - 1.0, for a progress bar.
  double get fraction => totalMinutes == 0 ? 1 : (_progress / totalMinutes).clamp(0.0, 1.0).toDouble();

  /// Advance the shuttle by [minutes] of simulated time.
  void tick(double minutes) {
    _progress = (_progress + minutes).clamp(0.0, totalMinutes).toDouble();
  }

  void reset() => _progress = 0;

  /// Index of the next stop the shuttle has not reached yet.
  /// Returns stops.length when the route is finished.
  int get nextStopIndex {
    for (var i = 0; i < _offsets.length; i++) {
      if (_offsets[i] > _progress) return i;
    }
    return _offsets.length;
  }

  /// Minutes until the shuttle reaches stop [index] (0 if already passed).
  double etaMinutes(int index) {
    final eta = _offsets[index] - _progress;
    return eta < 0 ? 0 : eta;
  }

  /// Current position as (lat, lng).
  (double, double) get position {
    final stops = route.stops;
    if (_progress <= 0) return (stops.first.lat, stops.first.lng);
    if (finished) return (stops.last.lat, stops.last.lng);

    for (var i = 0; i < _offsets.length - 1; i++) {
      final a = _offsets[i];
      final b = _offsets[i + 1];
      if (_progress >= a && _progress <= b) {
        final t = b == a ? 1.0 : (_progress - a) / (b - a);
        final lat = stops[i].lat + (stops[i + 1].lat - stops[i].lat) * t;
        final lng = stops[i].lng + (stops[i + 1].lng - stops[i].lng) * t;
        return (lat, lng);
      }
    }
    return (stops.last.lat, stops.last.lng);
  }
}
