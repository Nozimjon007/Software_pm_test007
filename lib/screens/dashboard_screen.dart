import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/nav_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/license_banner.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/seat_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/status_pill.dart';

/// Dashboard home: today's shuttles, open seats, license warning (NFR-04).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nav = context.read<NavController>();
    final day = state.serviceDay;
    final dayLabel = state.serviceDayIsToday ? 'Today' : 'Next service day';
    final routes = state.serviceDayRoutes;
    final overLimit = state.nonCompliantDriverCount();

    return PageBody(
      children: [
        PageHeader(
          title: 'Dashboard',
          subtitle: '$dayLabel · ${Fmt.shortDate(day)}'
              '${state.serviceDayIsToday ? '' : '  (no shuttles on weekends)'}',
          requirementIds: const ['FR-01', 'FR-02', 'NFR-04'],
          actions: [
            FilledButton.icon(
              onPressed: () => nav.go(AppTab.bookings),
              icon: const Icon(Icons.add),
              label: const Text('Book a seat'),
            ),
          ],
        ),
        LicenseBanner(
          license: state.license,
          today: state.today,
          onDetails: () => _showLicense(context, state.license),
        ),
        ResponsiveGrid(
          minItemWidth: 230,
          children: [
            StatCard(
              label: state.serviceDayIsToday ? 'Shuttles today' : 'Shuttles next service day',
              value: '${routes.length}',
              icon: Icons.directions_bus,
              onTap: () => nav.go(AppTab.routes),
            ),
            StatCard(
              label: 'Riders booked',
              value: '${state.ridersOnServiceDay}',
              icon: Icons.groups_2_outlined,
              color: AppColors.accent,
              onTap: () => nav.go(AppTab.bookings),
            ),
            StatCard(
              label: 'Open seats',
              value: '${state.openSeatsOnServiceDay}',
              icon: Icons.event_seat_outlined,
              color: const Color(0xFF6C5DD3),
              onTap: () => nav.go(AppTab.bookings),
            ),
            StatCard(
              label: 'Drivers over limit',
              value: '$overLimit',
              icon: Icons.timer_off_outlined,
              color: overLimit > 0 ? AppColors.danger : AppColors.accent,
              hint: overLimit > 0 ? 'Check hours log' : 'All compliant',
              onTap: () => nav.go(AppTab.hours),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Text(
              "$dayLabel's shuttles",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B2A3D)),
            ),
            const Spacer(),
            TextButton(onPressed: () => nav.go(AppTab.routes), child: const Text('All routes')),
          ],
        ),
        const SizedBox(height: 8),
        if (routes.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.directions_bus_outlined,
              title: 'No shuttles scheduled',
              message: 'Create a route to get started.',
            ),
          )
        else
          ResponsiveGrid(
            minItemWidth: 340,
            children: [
              for (final r in routes) _ShuttleCard(route: r, day: day),
            ],
          ),
        const SizedBox(height: 28),
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1B2A3D)),
        ),
        const SizedBox(height: 8),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: state.activity.isEmpty
              ? const EmptyState(icon: Icons.history, title: 'No activity yet', message: 'Actions you take appear here.')
              : Column(
                  children: [
                    for (final a in state.activity.take(8))
                      ListTile(
                        dense: true,
                        leading: const Icon(Icons.bolt, color: AppColors.accent, size: 20),
                        title: Text(a.text),
                        trailing: Text(Fmt.time(a.time), style: const TextStyle(color: AppColors.textMuted)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  void _showLicense(BuildContext context, TransportLicense license) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Passenger-transport license'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kv('Number', license.number),
            _kv('Issued by', license.issuedBy),
            _kv('Issued on', Fmt.date(license.issuedOn)),
            _kv('Expires on', Fmt.date(license.expiresOn)),
            const SizedBox(height: 8),
            const Text(
              'RideLine warns the organizer 30 days before the license expires (NFR-04).',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 90, child: Text(k, style: const TextStyle(color: AppColors.textMuted))),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );
}

class _ShuttleCard extends StatelessWidget {
  final ShuttleRoute route;
  final DateTime day;

  const _ShuttleCard({required this.route, required this.day});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nav = context.read<NavController>();
    final driver = state.driverById(route.driverId);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(route.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
              Text(
                '${route.departureTime} → ${route.arrivalTime}',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.badge_outlined, size: 16, color: AppColors.textMuted),
              const SizedBox(width: 6),
              if (driver != null)
                Expanded(child: Text(driver.name, style: const TextStyle(color: AppColors.textMuted)))
              else
                const StatusPill('No driver assigned', tone: PillTone.danger, icon: Icons.error_outline),
            ],
          ),
          const SizedBox(height: 12),
          SeatBar(taken: state.seatsTaken(route.id, day), capacity: route.capacity),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => nav.go(AppTab.bookings, routeId: route.id),
                icon: const Icon(Icons.event_seat_outlined, size: 18),
                label: const Text('Seats'),
              ),
              OutlinedButton.icon(
                onPressed: () => nav.go(AppTab.tracking, routeId: route.id),
                icon: const Icon(Icons.my_location, size: 18),
                label: const Text('Track'),
              ),
              if (driver == null)
                FilledButton.icon(
                  onPressed: () => nav.go(AppTab.drivers, routeId: route.id),
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Assign driver'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
