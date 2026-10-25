import 'package:flutter_test/flutter_test.dart';
import 'package:rideline/models/hours_entry.dart';
import 'package:rideline/services/compliance_service.dart';

/// FR-07 (hours log) and NFR-03 (legal limits).
void main() {
  final monday = DateTime(2026, 10, 19);

  HoursEntry e(int dayOffset, double worked, {double rest = 14}) => HoursEntry(
        driverId: 'd',
        date: DateTime(2026, 10, 19 + dayOffset),
        hoursWorked: worked,
        restHours: rest,
      );

  test('weekStart returns Monday', () {
    expect(ComplianceService.weekStart(DateTime(2026, 10, 23)), monday); // Friday
    expect(ComplianceService.weekStart(DateTime(2026, 10, 25)), monday); // Sunday
  });

  test('a normal week is compliant', () {
    final entries = [for (var i = 0; i < 5; i++) e(i, 8)];
    expect(ComplianceService.weeklyHours(entries, 'd', monday), 40);
    expect(ComplianceService.isCompliant(entries, 'd', monday), isTrue);
  });

  test('more than the daily limit is a violation', () {
    final entries = [e(0, 11)];
    final v = ComplianceService.violations(entries, 'd', monday);
    expect(v.single.type, ViolationType.dailyHours);
  });

  test('more than the weekly limit is a violation', () {
    final entries = [for (var i = 0; i < 5; i++) e(i, 9)]; // 45 h
    final v = ComplianceService.violations(entries, 'd', monday);
    expect(v.map((x) => x.type), contains(ViolationType.weeklyHours));
  });

  test('too little rest is a violation', () {
    final entries = [e(0, 8, rest: 9)];
    final v = ComplianceService.violations(entries, 'd', monday);
    expect(v.single.type, ViolationType.shortRest);
  });

  test('entries from other weeks are ignored', () {
    final entries = [
      HoursEntry(driverId: 'd', date: DateTime(2026, 10, 12), hoursWorked: 15, restHours: 5),
    ];
    expect(ComplianceService.isCompliant(entries, 'd', monday), isTrue);
  });
}
