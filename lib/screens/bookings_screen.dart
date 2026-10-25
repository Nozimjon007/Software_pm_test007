import 'dart:async';

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
import '../widgets/seat_bar.dart';
import '../widgets/status_pill.dart';

/// Seat booking: book, change, cancel a seat for an employee (FR-02).
/// A cancelled seat becomes available again immediately (FR-03).
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  String? _routeId;
  late DateTime _date;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    final nav = context.read<NavController>();
    _date = state.serviceDay;
    _routeId = nav.focusRouteId ?? (state.routes.isEmpty ? null : state.routes.first.id);
    // Refresh once per second so the "freed X s ago" label updates live.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  /// Next 5 days the selected route runs (starting from the service day).
  List<DateTime> _upcomingDays(ShuttleRoute route, DateTime from) {
    final days = <DateTime>[];
    var d = from;
    var guard = 0;
    while (days.length < 5 && guard < 60) {
      if (route.runsOn(d)) days.add(d);
      d = DateTime(d.year, d.month, d.day + 1);
      guard++;
    }
    return days;
  }

  void _snack(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
  }

  // ------------------------------------------------------------------ book
  Future<void> _openBookDialog(ShuttleRoute route, {int? seat}) async {
    final state = context.read<AppState>();
    final bookedIds = state.bookings
        .where((b) => b.isActive && Fmt.sameDay(b.date, _date))
        .map((b) => b.employeeId)
        .toSet();
    final free = state.employees.where((e) => !bookedIds.contains(e.id)).toList();

    if (free.isEmpty) {
      _snack('Every employee already has a seat on ${Fmt.shortDate(_date)}.');
      return;
    }

    String employeeId = free.first.id;
    String stopId = route.stops.first.id;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(seat == null ? 'Book a seat' : 'Book seat $seat'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${route.name} · ${Fmt.shortDate(_date)}', style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('book_employee'),
                  value: employeeId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Employee'),
                  items: [
                    for (final e in free)
                      DropdownMenuItem(value: e.id, child: Text('${e.name} · ${e.department}')),
                  ],
                  onChanged: (v) => setLocal(() => employeeId = v ?? employeeId),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: stopId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pickup stop'),
                  items: [
                    for (final s in route.stops.take(route.stops.length - 1))
                      DropdownMenuItem(value: s.id, child: Text('${s.time} · ${s.name}')),
                  ],
                  onChanged: (v) => setLocal(() => stopId = v ?? stopId),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              key: const Key('confirm_booking'),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Book seat'),
            ),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final error = state.bookSeat(
      routeId: route.id,
      employeeId: employeeId,
      stopId: stopId,
      date: _date,
      seatNumber: seat,
    );
    if (error != null) {
      _snack(error, error: true);
    } else {
      _snack('Seat booked for ${state.employeeById(employeeId).name}.');
    }
  }

  // ---------------------------------------------------------------- change
  Future<void> _openChangeDialog(ShuttleRoute route, Booking booking) async {
    final state = context.read<AppState>();
    final employee = state.employeeById(booking.employeeId);
    final days = _upcomingDays(route, state.serviceDay);
    if (!days.any((d) => Fmt.sameDay(d, booking.date))) days.insert(0, booking.date);

    String stopId = booking.stopId;
    DateTime date = days.firstWhere((d) => Fmt.sameDay(d, booking.date));

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text('Change booking · ${employee.name}'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: stopId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Pickup stop'),
                  items: [
                    for (final s in route.stops.take(route.stops.length - 1))
                      DropdownMenuItem(value: s.id, child: Text('${s.time} · ${s.name}')),
                  ],
                  onChanged: (v) => setLocal(() => stopId = v ?? stopId),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<DateTime>(
                  value: date,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Date'),
                  items: [
                    for (final d in days) DropdownMenuItem(value: d, child: Text(Fmt.shortDate(d))),
                  ],
                  onChanged: (v) => setLocal(() => date = v ?? date),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save changes')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    final error = state.changeBooking(booking.id, stopId: stopId, date: date);
    if (error != null) {
      _snack(error, error: true);
    } else {
      _snack('Booking updated for ${employee.name}.');
    }
  }

  // ---------------------------------------------------------------- cancel
  Future<void> _confirmCancel(Booking booking) async {
    final state = context.read<AppState>();
    final employee = state.employeeById(booking.employeeId);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this seat?'),
        content: Text('${employee.name} · seat ${booking.seatNumber} · ${Fmt.shortDate(booking.date)}\n\n'
            'The seat will be released for someone else straight away.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep')),
          FilledButton(
            key: const Key('confirm_cancel'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel seat'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final started = DateTime.now();
    state.cancelBooking(booking.id);
    final ms = DateTime.now().difference(started).inMilliseconds;
    _snack('Seat ${booking.seatNumber} is available again (released in $ms ms · FR-03 limit: 60 s).');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final routes = state.routes;

    if (routes.isEmpty) {
      return const PageBody(children: [
        PageHeader(title: 'Seat booking', subtitle: 'Book seats for employees.', requirementIds: ['FR-02', 'FR-03']),
        AppCard(
          child: EmptyState(icon: Icons.alt_route, title: 'No routes', message: 'Create a route first.'),
        ),
      ]);
    }

    final route = state.routeById(_routeId ?? '') ?? routes.first;
    final days = _upcomingDays(route, state.serviceDay);
    if (days.isNotEmpty && !days.any((d) => Fmt.sameDay(d, _date))) _date = days.first;

    final bookings = state.activeBookings(route.id, _date)..sort((a, b) => a.seatNumber.compareTo(b.seatNumber));
    final taken = {for (final b in bookings) b.seatNumber: b};
    final cancelledToday = state.bookings
        .where((b) => !b.isActive && b.routeId == route.id && Fmt.sameDay(b.date, _date) && state.releasedSeats.containsKey(b.id))
        .toList();

    return PageBody(
      children: [
        const PageHeader(
          title: 'Seat booking',
          subtitle: 'Pick a route and date, then tap a free seat to book it for an employee.',
          requirementIds: ['FR-02', 'FR-03'],
        ),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                key: const Key('booking_route'),
                value: route.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Route', prefixIcon: Icon(Icons.alt_route)),
                items: [
                  for (final r in routes)
                    DropdownMenuItem(value: r.id, child: Text('${r.name}  (${r.departureTime})')),
                ],
                onChanged: (v) => setState(() => _routeId = v),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in days)
                    ChoiceChip(
                      label: Text(Fmt.shortDate(d)),
                      selected: Fmt.sameDay(d, _date),
                      onSelected: (_) => setState(() => _date = d),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SeatBar(taken: bookings.length, capacity: route.capacity),
            ],
          ),
        ),
        const SizedBox(height: 18),
        ResponsiveGrid(
          minItemWidth: 420,
          children: [
            // ---------------------------------------------------- seat map
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Seat map', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('book_seat_button'),
                        onPressed: bookings.length >= route.capacity ? null : () => _openBookDialog(route),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Book seat'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Wrap(
                    spacing: 14,
                    children: [
                      _Legend(color: AppColors.primary, label: 'Booked'),
                      _Legend(color: AppColors.border, label: 'Free'),
                      _Legend(color: AppColors.accent, label: 'Just released'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (var n = 1; n <= route.capacity; n++)
                        _Seat(
                          number: n,
                          booking: taken[n],
                          employee: taken[n] == null ? null : state.employeeById(taken[n]!.employeeId),
                          releasedAt: taken[n] == null ? state.seatReleasedAt(route.id, _date, n) : null,
                          onTap: () {
                            final b = taken[n];
                            if (b == null) {
                              _openBookDialog(route, seat: n);
                            } else {
                              _openChangeDialog(route, b);
                            }
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // ------------------------------------------------- passengers
            AppCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Passengers (${bookings.length})', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 8),
                  if (bookings.isEmpty)
                    const EmptyState(icon: Icons.event_seat_outlined, title: 'No bookings', message: 'Tap a free seat to book.')
                  else
                    for (final b in bookings) _passengerTile(state, route, b),
                  if (cancelledToday.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text('Cancelled this session', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    for (final b in cancelledToday)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_busy, color: AppColors.textMuted),
                        title: Text(
                          state.employeeById(b.employeeId).name,
                          style: const TextStyle(decoration: TextDecoration.lineThrough),
                        ),
                        subtitle: Text('Seat ${b.seatNumber} released at ${Fmt.time(b.cancelledAt!)}'),
                        trailing: const StatusPill('Seat freed', tone: PillTone.ok, icon: Icons.check),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _passengerTile(AppState state, ShuttleRoute route, Booking b) {
    final e = state.employeeById(b.employeeId);
    final stop = state.stopById(route, b.stopId);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withAlpha(25),
        child: Text(e.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Seat ${b.seatNumber} · ${stop?.time ?? ''} ${stop?.name ?? ''}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Change',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _openChangeDialog(route, b),
          ),
          IconButton(
            key: Key('cancel_${b.id}'),
            tooltip: 'Cancel seat',
            icon: const Icon(Icons.cancel_outlined, color: AppColors.danger),
            onPressed: () => _confirmCancel(b),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  final int number;
  final Booking? booking;
  final Employee? employee;
  final DateTime? releasedAt;
  final VoidCallback onTap;

  const _Seat({
    required this.number,
    required this.booking,
    required this.employee,
    required this.releasedAt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final booked = booking != null;
    final secondsAgo = releasedAt == null ? null : DateTime.now().difference(releasedAt!).inSeconds;
    final justReleased = secondsAgo != null && secondsAgo < 60;

    final bg = booked
        ? AppColors.primary
        : justReleased
            ? AppColors.successBg
            : Colors.white;
    final border = booked
        ? AppColors.primary
        : justReleased
            ? AppColors.accent
            : AppColors.border;

    return Tooltip(
      message: booked
          ? '${employee?.name} – tap to change'
          : justReleased
              ? 'Released ${secondsAgo}s ago – available again'
              : 'Free – tap to book',
      child: InkWell(
        key: Key('seat_$number'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border, width: justReleased ? 2 : 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$number',
                style: TextStyle(
                  fontSize: 11,
                  color: booked ? Colors.white70 : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              if (booked)
                Text(employee?.initials ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))
              else if (justReleased)
                const Text('FREED', style: TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.w900))
              else
                const Icon(Icons.event_seat_outlined, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
