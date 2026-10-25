import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/app_state.dart';
import '../services/compliance_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_grid.dart';
import '../widgets/status_pill.dart';

/// Driver working-hours log (FR-07) with legal-limit warnings (NFR-03).
class HoursScreen extends StatefulWidget {
  const HoursScreen({super.key});

  @override
  State<HoursScreen> createState() => _HoursScreenState();
}

class _HoursScreenState extends State<HoursScreen> {
  int _weekOffset = 0; // 0 = this week, -1 = last week

  DateTime _monday(AppState state) {
    final m = ComplianceService.weekStart(state.today);
    return DateTime(m.year, m.month, m.day + 7 * _weekOffset);
  }

  HoursEntry? _entry(AppState state, String driverId, DateTime day) {
    for (final e in state.hours) {
      if (e.driverId == driverId && Fmt.sameDay(e.date, day)) return e;
    }
    return null;
  }

  Future<void> _logHoursDialog(AppState state, DateTime monday) async {
    String driverId = state.drivers.first.id;
    DateTime day = state.today.weekday <= 5 ? state.today : monday;
    final hoursCtrl = TextEditingController(text: '8');
    final restCtrl = TextEditingController(text: '14');
    final weekDays = [for (var i = 0; i < 5; i++) DateTime(monday.year, monday.month, monday.day + i)];
    if (!weekDays.any((d) => Fmt.sameDay(d, day))) day = weekDays.first;
    day = weekDays.firstWhere((d) => Fmt.sameDay(d, day));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Log working hours'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: driverId,
                  decoration: const InputDecoration(labelText: 'Driver'),
                  items: [
                    for (final d in state.drivers) DropdownMenuItem(value: d.id, child: Text(d.name)),
                  ],
                  onChanged: (v) => setLocal(() => driverId = v ?? driverId),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DateTime>(
                  value: day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: [
                    for (final d in weekDays) DropdownMenuItem(value: d, child: Text(Fmt.shortDate(d))),
                  ],
                  onChanged: (v) => setLocal(() => day = v ?? day),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('hours_worked'),
                        controller: hoursCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Hours worked'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: restCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Rest after shift (h)'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    final worked = double.tryParse(hoursCtrl.text.replaceAll(',', '.'));
    final rest = double.tryParse(restCtrl.text.replaceAll(',', '.'));
    // (Controllers are not disposed here on purpose: the dialog's closing
    // animation may still be using them. They are garbage-collected.)
    if (ok != true || !mounted) return;

    if (worked == null || rest == null || worked < 0 || worked > 24 || rest < 0 || rest > 48) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid hours.'), backgroundColor: AppColors.danger),
      );
      return;
    }
    state.logHours(driverId: driverId, date: day, hoursWorked: worked, restHours: rest);

    final over = worked > ComplianceService.maxDailyHours || rest < ComplianceService.minRestHours;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(over
            ? '⚠ Saved – this entry breaks the legal limit (NFR-03).'
            : 'Hours saved.'),
        backgroundColor: over ? AppColors.danger : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final monday = _monday(state);
    final days = [for (var i = 0; i < 5; i++) DateTime(monday.year, monday.month, monday.day + i)];
    final friday = days.last;

    final allViolations = <(Driver, ComplianceViolation)>[
      for (final d in state.drivers)
        for (final v in ComplianceService.violations(state.hours, d.id, monday)) (d, v),
    ];

    return PageBody(
      children: [
        PageHeader(
          title: 'Driver hours',
          subtitle: 'Working and rest time per driver, checked against the legal limits.',
          requirementIds: const ['FR-07', 'NFR-03'],
          actions: [
            FilledButton.icon(
              key: const Key('log_hours'),
              onPressed: () => _logHoursDialog(state, monday),
              icon: const Icon(Icons.add_alarm),
              label: const Text('Log hours'),
            ),
          ],
        ),
        if (allViolations.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.dangerBg,
              borderRadius: BorderRadius.circular(AppTheme.radius),
              border: Border.all(color: AppColors.danger.withAlpha(80)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.gavel, color: AppColors.danger),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${allViolations.length} legal-limit warning(s) this week',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.danger),
                      ),
                      const SizedBox(height: 6),
                      for (final (d, v) in allViolations)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '• ${d.name} – ${v.type == ViolationType.weeklyHours ? 'week' : Fmt.shortDate(v.date)}: ${v.message}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        AppCard(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous week',
                      onPressed: () => setState(() => _weekOffset--),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${Fmt.shortDate(monday)} – ${Fmt.shortDate(friday)}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      tooltip: 'Next week',
                      onPressed: _weekOffset >= 0 ? null : () => setState(() => _weekOffset++),
                      icon: const Icon(Icons.chevron_right),
                    ),
                    const Spacer(),
                    if (_weekOffset == 0) const StatusPill('This week', tone: PillTone.info),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingTextStyle: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary),
                  columns: [
                    const DataColumn(label: Text('Driver')),
                    for (final d in days) DataColumn(label: Text(Fmt.shortDate(d)), numeric: true),
                    const DataColumn(label: Text('Week total'), numeric: true),
                    const DataColumn(label: Text('Status')),
                  ],
                  rows: [
                    for (final driver in state.drivers) _row(state, driver, days, monday),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          minItemWidth: 240,
          children: [
            _LimitCard(
              icon: Icons.today,
              title: '${ComplianceService.maxDailyHours.toStringAsFixed(0)} h',
              text: 'Max working time per day',
            ),
            _LimitCard(
              icon: Icons.date_range,
              title: '${ComplianceService.maxWeeklyHours.toStringAsFixed(0)} h',
              text: 'Max working time per week',
            ),
            _LimitCard(
              icon: Icons.bedtime_outlined,
              title: '${ComplianceService.minRestHours.toStringAsFixed(0)} h',
              text: 'Min rest between shifts',
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Limits follow Uzbekistan\'s rules on driver working and rest time (lex.uz/docs/-2234877). '
          'They are configured in ComplianceService.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  DataRow _row(AppState state, Driver driver, List<DateTime> days, DateTime monday) {
    final total = ComplianceService.weeklyHours(state.hours, driver.id, monday);
    final violations = ComplianceService.violations(state.hours, driver.id, monday);

    return DataRow(
      cells: [
        DataCell(Text(driver.name, style: const TextStyle(fontWeight: FontWeight.w600))),
        for (final d in days) DataCell(_hoursCell(_entry(state, driver.id, d))),
        DataCell(Text(
          total.toStringAsFixed(1),
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: total > ComplianceService.maxWeeklyHours ? AppColors.danger : null,
          ),
        )),
        DataCell(violations.isEmpty
            ? const StatusPill('OK', tone: PillTone.ok, icon: Icons.check)
            : StatusPill('${violations.length} warning(s)', tone: PillTone.danger, icon: Icons.warning_amber)),
      ],
    );
  }

  Widget _hoursCell(HoursEntry? e) {
    if (e == null) return const Text('–', style: TextStyle(color: AppColors.textMuted));
    final overDay = e.hoursWorked > ComplianceService.maxDailyHours;
    final shortRest = e.restHours < ComplianceService.minRestHours;
    return Tooltip(
      message: 'Worked ${e.hoursWorked.toStringAsFixed(1)} h · rest ${e.restHours.toStringAsFixed(1)} h',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (overDay || shortRest) ...[
            Icon(shortRest && !overDay ? Icons.bedtime : Icons.warning_amber, size: 14, color: AppColors.danger),
            const SizedBox(width: 3),
          ],
          Text(
            e.hoursWorked.toStringAsFixed(1),
            style: TextStyle(
              color: (overDay || shortRest) ? AppColors.danger : null,
              fontWeight: (overDay || shortRest) ? FontWeight.w800 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _LimitCard({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              Text(text, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}
