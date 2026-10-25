import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_card.dart';
import '../widgets/requirement_tag.dart';

/// Create a route with stops, dates and times (FR-01).
class RouteFormScreen extends StatefulWidget {
  const RouteFormScreen({super.key});

  @override
  State<RouteFormScreen> createState() => _RouteFormScreenState();
}

class _StopDraft {
  Place? place;
  TimeOfDay time;
  _StopDraft(this.place, this.time);
}

class _RouteFormScreenState extends State<RouteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _capacity = TextEditingController(text: '12');
  final _price = TextEditingController(text: '12000');
  final Set<int> _weekdays = {1, 2, 3, 4, 5};
  late DateTime _start;
  late DateTime _end;
  String? _error;

  late final List<_StopDraft> _stops;

  @override
  void initState() {
    super.initState();
    final today = context.read<AppState>().today;
    _start = today;
    _end = DateTime(today.year, today.month + 3, today.day);
    final office = MockData.places.first;
    _stops = [
      _StopDraft(null, const TimeOfDay(hour: 8, minute: 0)),
      _StopDraft(office, const TimeOfDay(hour: 8, minute: 30)),
    ];
  }

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _price.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _stops[index].time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _stops[index].time = picked);
  }

  Future<void> _pickDate({required bool start}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : _end,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
        if (_end.isBefore(_start)) _end = _start;
      } else {
        _end = picked;
      }
    });
  }

  void _addStop() {
    final last = _stops.last.time;
    // Insert before the final stop (usually the office), 10 min earlier.
    final m = _minutes(last) - 10;
    setState(() {
      _stops.insert(_stops.length - 1, _StopDraft(null, TimeOfDay(hour: m ~/ 60, minute: m % 60)));
    });
  }

  void _save() {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    if (_weekdays.isEmpty) {
      setState(() => _error = 'Choose at least one weekday.');
      return;
    }
    if (_end.isBefore(_start)) {
      setState(() => _error = 'End date must be after start date.');
      return;
    }
    if (_stops.length < 2) {
      setState(() => _error = 'A route needs at least two stops.');
      return;
    }
    for (var i = 0; i < _stops.length; i++) {
      if (_stops[i].place == null) {
        setState(() => _error = 'Choose a place for stop ${i + 1}.');
        return;
      }
      if (i > 0 && _minutes(_stops[i].time) <= _minutes(_stops[i - 1].time)) {
        setState(() => _error = 'Stop ${i + 1} must be later than stop $i.');
        return;
      }
    }

    final route = context.read<AppState>().addRoute(
          name: _name.text.trim(),
          stops: [
            for (final s in _stops)
              Stop(id: '', name: s.place!.name, time: _fmtTime(s.time), lat: s.place!.lat, lng: s.place!.lng),
          ],
          weekdays: Set.of(_weekdays),
          startDate: _start,
          endDate: _end,
          capacity: int.parse(_capacity.text),
          pricePerSeat: int.parse(_price.text),
        );
    Navigator.of(context).pop(route);
  }

  String? _positiveInt(String? v) {
    final n = int.tryParse(v ?? '');
    if (n == null || n <= 0) return 'Enter a number above 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('New route'),
            SizedBox(width: 12),
            RequirementTags(['FR-01']),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('Route details'),
                  AppCard(
                    child: Column(
                      children: [
                        TextFormField(
                          key: const Key('route_name'),
                          controller: _name,
                          decoration: const InputDecoration(
                            labelText: 'Route name',
                            hintText: 'e.g. Beruniy → Tashkent City Office',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Give the route a name' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _capacity,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Seats in shuttle'),
                                validator: _positiveInt,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: TextFormField(
                                controller: _price,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Price per seat (UZS)'),
                                validator: _positiveInt,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  _section('Dates and days'),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var d = 1; d <= 7; d++)
                              FilterChip(
                                label: Text(Fmt.weekday(d)),
                                selected: _weekdays.contains(d),
                                onSelected: (on) => setState(() => on ? _weekdays.add(d) : _weekdays.remove(d)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(start: true),
                                icon: const Icon(Icons.event),
                                label: Text('From ${Fmt.date(_start)}'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _pickDate(start: false),
                                icon: const Icon(Icons.event_available),
                                label: Text('Until ${Fmt.date(_end)}'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(child: _section('Stops and times')),
                      TextButton.icon(
                        key: const Key('add_stop'),
                        onPressed: _addStop,
                        icon: const Icon(Icons.add_location_alt_outlined),
                        label: const Text('Add stop'),
                      ),
                    ],
                  ),
                  AppCard(
                    child: Column(
                      children: [
                        for (var i = 0; i < _stops.length; i++) _stopRow(i),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        key: const Key('save_route'),
                        onPressed: _save,
                        icon: const Icon(Icons.check),
                        label: const Text('Create route'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      );

  Widget _stopRow(int i) {
    final s = _stops[i];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary.withAlpha(25),
            child: Text('${i + 1}', style: const TextStyle(fontSize: 12, color: AppColors.primary)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<Place>(
              key: Key('stop_place_$i'),
              value: s.place,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Place'),
              items: [
                for (final p in MockData.places) DropdownMenuItem(value: p, child: Text(p.name)),
              ],
              onChanged: (p) => setState(() => s.place = p),
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: () => _pickTime(i),
            icon: const Icon(Icons.schedule, size: 18),
            label: Text(_fmtTime(s.time)),
          ),
          IconButton(
            tooltip: 'Remove stop',
            onPressed: _stops.length <= 2 ? null : () => setState(() => _stops.removeAt(i)),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
