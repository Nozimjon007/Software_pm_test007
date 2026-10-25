import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/nav_controller.dart';
import '../services/notification_service.dart';
import '../services/tracking_simulator.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/schematic_map.dart';
import '../widgets/status_pill.dart';

/// Live tracking map with a SIMULATED GPS feed, plus simulated rider
/// arrival notifications (FR-08).
class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  static const _tickEvery = Duration(milliseconds: 200);

  late String _routeId;
  TrackingSimulator? _sim;
  Timer? _timer;
  double _speed = 1; // 1x = one route-minute every ~0.8 s
  bool _realMap = true;
  final Set<String> _notifiedStops = {};
  String? _lastAlert;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final focus = context.read<NavController>().focusRouteId;
    _routeId = focus ?? (state.routes.isEmpty ? '' : state.routes.first.id);
    _resetFor(state);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _resetFor(AppState state) {
    _timer?.cancel();
    _timer = null;
    _notifiedStops.clear();
    _lastAlert = null;
    final route = state.routeById(_routeId);
    _sim = (route == null || route.stops.length < 2) ? null : TrackingSimulator(route);
  }

  bool get _running => _timer != null;

  void _start() {
    if (_sim == null) return;
    if (_sim!.finished) _sim!.reset();
    _timer = Timer.periodic(_tickEvery, (_) => _onTick());
    setState(() {});
  }

  void _pause() {
    _timer?.cancel();
    _timer = null;
    setState(() {});
  }

  void _onTick() {
    final sim = _sim;
    if (sim == null || !mounted) return;
    sim.tick(0.25 * _speed);
    _checkNotifications(sim);
    if (sim.finished) {
      _timer?.cancel();
      _timer = null;
    }
    setState(() {});
  }

  /// FR-08: when the shuttle is <= 10 min from a stop, notify riders
  /// booked at that stop (simulated SMS + email).
  void _checkNotifications(TrackingSimulator sim) {
    final state = context.read<AppState>();
    final route = sim.route;
    for (var i = 1; i < route.stops.length - 1; i++) {
      final stop = route.stops[i];
      if (_notifiedStops.contains(stop.id)) continue;
      if (i < sim.nextStopIndex) continue; // already passed
      final eta = sim.etaMinutes(i);
      if (eta <= NotificationService.leadMinutes) {
        _notifiedStops.add(stop.id);
        final riders = state.ridersAtStop(route.id, stop.id);
        if (riders.isEmpty) continue;
        final records = NotificationService.notifyRiders(
          riders: riders,
          route: route,
          stop: stop,
          etaMinutes: eta.ceil(),
        );
        state.addNotifications(records);
        _lastAlert = 'Notification sent to ${riders.length} rider(s) at ${stop.name} '
            '(SMS + email, ~${eta.ceil()} min before arrival)';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📩 $_lastAlert'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final routes = state.routes;

    if (routes.isEmpty || _sim == null) {
      return const PageBody(children: [
        PageHeader(title: 'Live tracking', subtitle: 'No route to track yet.', requirementIds: ['FR-08']),
      ]);
    }

    final sim = _sim!;
    final route = sim.route;
    final (lat, lng) = sim.position;
    final driver = state.driverById(route.driverId);

    final controls = AppCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 340,
            child: DropdownButtonFormField<String>(
              value: _routeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Shuttle', prefixIcon: Icon(Icons.directions_bus)),
              items: [
                for (final r in routes) DropdownMenuItem(value: r.id, child: Text(r.name)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _routeId = v;
                  _resetFor(state);
                });
              },
            ),
          ),
          _running
              ? FilledButton.icon(
                  onPressed: _pause,
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                )
              : FilledButton.icon(
                  key: const Key('start_tracking'),
                  onPressed: _start,
                  icon: const Icon(Icons.play_arrow),
                  label: Text(sim.progress == 0 ? 'Start trip' : (sim.finished ? 'Replay' : 'Resume')),
                ),
          OutlinedButton.icon(
            onPressed: () => setState(() => _resetFor(state)),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Reset'),
          ),
          SegmentedButton<double>(
            segments: const [
              ButtonSegment(value: 1.0, label: Text('1×')),
              ButtonSegment(value: 2.0, label: Text('2×')),
              ButtonSegment(value: 4.0, label: Text('4×')),
            ],
            selected: {_speed},
            onSelectionChanged: (s) => setState(() => _speed = s.first),
          ),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Map'), icon: Icon(Icons.public)),
              ButtonSegment(value: false, label: Text('Simple'), icon: Icon(Icons.timeline)),
            ],
            selected: {_realMap},
            onSelectionChanged: (s) => setState(() => _realMap = s.first),
          ),
        ],
      ),
    );

    final map = ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: _realMap
                ? _RealMap(key: ValueKey(route.id), route: route, busLat: lat, busLng: lng, nextStop: sim.nextStopIndex)
                : SchematicMap(stops: route.stops, busLat: lat, busLng: lng, nextStopIndex: sim.nextStopIndex),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: _running ? AppColors.accent : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    _running ? 'LIVE · simulated GPS' : (sim.finished ? 'Arrived' : 'Paused · simulated GPS'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final panel = _SidePanel(
      route: route,
      sim: sim,
      driverName: driver?.name,
      lastAlert: _lastAlert,
      notifications: state.notifications,
    );

    return PageBody(
      children: [
        const PageHeader(
          title: 'Live tracking',
          subtitle: 'Shuttle position on the map. Riders get a text/email 10 minutes before arrival.',
          requirementIds: ['FR-08'],
        ),
        controls,
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            if (c.maxWidth >= 900) {
              return SizedBox(
                height: 560,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: map),
                    const SizedBox(width: 16),
                    SizedBox(width: 340, child: panel),
                  ],
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 380, child: map),
                const SizedBox(height: 16),
                SizedBox(height: 520, child: panel),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Real OpenStreetMap tiles via flutter_map (needs internet).
class _RealMap extends StatelessWidget {
  final ShuttleRoute route;
  final double busLat;
  final double busLng;
  final int nextStop;

  const _RealMap({
    super.key,
    required this.route,
    required this.busLat,
    required this.busLng,
    required this.nextStop,
  });

  @override
  Widget build(BuildContext context) {
    final points = [for (final s in route.stops) LatLng(s.lat, s.lng)];
    final center = LatLng(
      points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
      points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
    );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12.6),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'uz.newuu.rideline',
            ),
            PolylineLayer(
              polylines: [
                Polyline(points: points, strokeWidth: 6, color: AppColors.primary),
              ],
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < route.stops.length; i++)
                  Marker(
                    point: points[i],
                    width: 26,
                    height: 26,
                    child: Tooltip(
                      message: '${route.stops[i].time} ${route.stops[i].name}',
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: i < nextStop ? AppColors.accent : AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    ),
                  ),
                Marker(
                  point: LatLng(busLat, busLng),
                  width: 46,
                  height: 46,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 8)],
                    ),
                    child: const Icon(Icons.directions_bus, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 6,
          bottom: 4,
          child: Container(
            color: Colors.white70,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }
}

class _SidePanel extends StatelessWidget {
  final ShuttleRoute route;
  final TrackingSimulator sim;
  final String? driverName;
  final String? lastAlert;
  final List<NotificationRecord> notifications;

  const _SidePanel({
    required this.route,
    required this.sim,
    required this.driverName,
    required this.lastAlert,
    required this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    final next = sim.nextStopIndex;
    final routeNotifications = notifications.where((n) => n.message.contains(route.name)).toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(route.name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Driver: ${driverName ?? 'not assigned'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: sim.fraction,
            minHeight: 8,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: AppColors.border,
            color: AppColors.accent,
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < route.stops.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    i < next ? Icons.check_circle : (i == next ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                    size: 18,
                    color: i < next ? AppColors.accent : (i == next ? AppColors.primary : AppColors.textMuted),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text('${route.stops[i].time}  ${route.stops[i].name}', style: const TextStyle(fontSize: 13))),
                  if (i < next)
                    const Text('passed', style: TextStyle(fontSize: 12, color: AppColors.textMuted))
                  else
                    Text('${sim.etaMinutes(i).ceil()} min',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i == next ? AppColors.primary : AppColors.textMuted,
                        )),
                ],
              ),
            ),
          const Divider(height: 22),
          const Row(
            children: [
              Text('Rider notifications', style: TextStyle(fontWeight: FontWeight.w800)),
              Spacer(),
              StatusPill('Simulated', tone: PillTone.warning),
            ],
          ),
          const SizedBox(height: 8),
          if (lastAlert != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(8)),
              child: Text('✓ $lastAlert', style: const TextStyle(color: Color(0xFF0B6B5B), fontSize: 12)),
            ),
          Expanded(
            child: routeNotifications.isEmpty
                ? const Text(
                    'Press "Start trip". When the shuttle is 10 min from a stop, riders booked there get a text and an email.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  )
                : ListView.builder(
                    itemCount: routeNotifications.length,
                    itemBuilder: (_, i) {
                      final n = routeNotifications[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(n.channel == NotificationChannel.sms ? Icons.sms_outlined : Icons.email_outlined, size: 20),
                        title: Text('${n.employeeName} · ${n.destination}', style: const TextStyle(fontSize: 12)),
                        subtitle: Text(n.message, style: const TextStyle(fontSize: 11)),
                        trailing: Text(Fmt.time(n.sentAt), style: const TextStyle(fontSize: 11)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
