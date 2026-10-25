import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/nav_controller.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/status_pill.dart';
import 'route_form_screen.dart';

/// List of shuttle routes + create / delete (FR-01).
class RoutesScreen extends StatelessWidget {
  const RoutesScreen({super.key});

  Future<void> _openForm(BuildContext context) async {
    final created = await Navigator.of(context).push<ShuttleRoute>(
      MaterialPageRoute(builder: (_) => const RouteFormScreen()),
    );
    if (created != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Route "${created.name}" created with ${created.stops.length} stops.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final routes = state.routes;

    return PageBody(
      children: [
        PageHeader(
          title: 'Routes',
          subtitle: 'Shuttle routes between offices and pickup points.',
          requirementIds: const ['FR-01'],
          actions: [
            FilledButton.icon(
              key: const Key('new_route'),
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add_road),
              label: const Text('New route'),
            ),
          ],
        ),
        if (routes.isEmpty)
          const AppCard(
            child: EmptyState(
              icon: Icons.alt_route,
              title: 'No routes yet',
              message: 'Create your first route with stops, dates and times.',
            ),
          )
        else
          for (final r in routes) ...[
            _RouteCard(route: r),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _RouteCard extends StatelessWidget {
  final ShuttleRoute route;
  const _RouteCard({required this.route});

  void _confirmDelete(BuildContext context) {
    final state = context.read<AppState>();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete route?'),
        content: Text('"${route.name}" and all its bookings will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              state.deleteRoute(route.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(22),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.alt_route, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(route.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        StatusPill(Fmt.weekdays(route.weekdays), tone: PillTone.info, icon: Icons.calendar_month),
                        StatusPill('${route.departureTime} → ${route.arrivalTime}', icon: Icons.schedule),
                        StatusPill('${route.capacity} seats', icon: Icons.event_seat),
                        StatusPill('${Fmt.money(route.pricePerSeat)} / seat', icon: Icons.payments_outlined),
                        if (driver != null)
                          StatusPill(driver.name, tone: PillTone.ok, icon: Icons.badge)
                        else
                          const StatusPill('No driver', tone: PillTone.danger, icon: Icons.error_outline),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'seats') nav.go(AppTab.bookings, routeId: route.id);
                  if (v == 'driver') nav.go(AppTab.drivers, routeId: route.id);
                  if (v == 'track') nav.go(AppTab.tracking, routeId: route.id);
                  if (v == 'delete') _confirmDelete(context);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'seats', child: Text('Manage seats')),
                  PopupMenuItem(value: 'driver', child: Text('Assign driver')),
                  PopupMenuItem(value: 'track', child: Text('Live tracking')),
                  PopupMenuDivider(),
                  PopupMenuItem(value: 'delete', child: Text('Delete route')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _StopsTimeline(stops: route.stops),
          const SizedBox(height: 10),
          Text(
            'Runs ${Fmt.date(route.startDate)} – ${Fmt.date(route.endDate)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// Horizontal list of stops: ● 07:45 Chilonzor — ● 07:55 ...
class _StopsTimeline extends StatelessWidget {
  final List<Stop> stops;
  const _StopsTimeline({required this.stops});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      i == stops.length - 1 ? Icons.flag_circle : Icons.circle,
                      size: i == stops.length - 1 ? 18 : 12,
                      color: i == 0
                          ? AppColors.accent
                          : i == stops.length - 1
                              ? AppColors.primary
                              : AppColors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(stops[i].time, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(stops[i].name, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            if (i < stops.length - 1)
              Container(
                width: 36,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}
