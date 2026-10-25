import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/compliance_service.dart';
import '../services/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/status_pill.dart';

/// Assign or switch the driver of a route at any time (FR-04).
class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key});

  Future<void> _assign(BuildContext context, ShuttleRoute route) async {
    final state = context.read<AppState>();
    final monday = ComplianceService.weekStart(state.today);

    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(route.driverId == null ? 'Assign driver' : 'Switch driver'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(route.name, style: const TextStyle(color: AppColors.textMuted)),
          ),
          for (final d in state.drivers)
            SimpleDialogOption(
              key: Key('pick_driver_${d.id}'),
              onPressed: () => Navigator.pop(ctx, d.id),
              child: _DriverOption(
                driver: d,
                hours: ComplianceService.weeklyHours(state.hours, d.id, monday),
                compliant: ComplianceService.isCompliant(state.hours, d.id, monday),
                current: d.id == route.driverId,
                otherRoutes: state.routesForDriver(d.id).where((r) => r.id != route.id).length,
              ),
            ),
        ],
      ),
    );

    if (picked == null || picked == route.driverId || !context.mounted) return;
    final result = state.assignDriver(route.id, picked);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(result.message)));

    if (result.warning != null) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 36),
          title: const Text('Please check'),
          content: Text(result.warning!),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final focus = context.read<NavController>().focusRouteId;
    final monday = ComplianceService.weekStart(state.today);

    return PageBody(
      children: [
        const PageHeader(
          title: 'Driver assignment',
          subtitle: 'Assign a driver to each route, or switch drivers at any time.',
          requirementIds: ['FR-04'],
        ),
        const Text('Routes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        for (final r in state.routes) ...[
          _RouteDriverRow(
            route: r,
            driver: state.driverById(r.driverId),
            highlighted: r.id == focus,
            onAssign: () => _assign(context, r),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const Text('Drivers', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        ResponsiveGrid(
          minItemWidth: 260,
          children: [
            for (final d in state.drivers)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withAlpha(25),
                          child: const Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(d.vehicle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    Text('${d.phone} · License ${d.licenseNumber}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        StatusPill('${state.routesForDriver(d.id).length} route(s)', tone: PillTone.info),
                        if (ComplianceService.isCompliant(state.hours, d.id, monday))
                          StatusPill(
                            '${ComplianceService.weeklyHours(state.hours, d.id, monday).toStringAsFixed(1)} h this week',
                            tone: PillTone.ok,
                          )
                        else
                          const StatusPill('Over limit', tone: PillTone.danger, icon: Icons.warning_amber),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RouteDriverRow extends StatelessWidget {
  final ShuttleRoute route;
  final Driver? driver;
  final bool highlighted;
  final VoidCallback onAssign;

  const _RouteDriverRow({
    required this.route,
    required this.driver,
    required this.highlighted,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderColor: highlighted ? AppColors.primary : null,
      child: Row(
        children: [
          const Icon(Icons.alt_route, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                if (driver != null)
                  Text('Driver: ${driver!.name} · ${driver!.vehicle}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
                else
                  const StatusPill('No driver assigned', tone: PillTone.danger, icon: Icons.error_outline),
              ],
            ),
          ),
          const SizedBox(width: 12),
          driver == null
              ? FilledButton.icon(
                  key: Key('assign_${route.id}'),
                  onPressed: onAssign,
                  icon: const Icon(Icons.person_add_alt, size: 18),
                  label: const Text('Assign'),
                )
              : OutlinedButton.icon(
                  key: Key('assign_${route.id}'),
                  onPressed: onAssign,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Switch'),
                ),
        ],
      ),
    );
  }
}

class _DriverOption extends StatelessWidget {
  final Driver driver;
  final double hours;
  final bool compliant;
  final bool current;
  final int otherRoutes;

  const _DriverOption({
    required this.driver,
    required this.hours,
    required this.compliant,
    required this.current,
    required this.otherRoutes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(current ? Icons.radio_button_checked : Icons.radio_button_unchecked,
            color: current ? AppColors.primary : AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${hours.toStringAsFixed(1)} h this week'
                '${otherRoutes > 0 ? ' · on $otherRoutes other route(s)' : ''}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        if (!compliant) const StatusPill('Over limit', tone: PillTone.danger),
        if (current) const StatusPill('Current', tone: PillTone.info),
      ],
    );
  }
}
