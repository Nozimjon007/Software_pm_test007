import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rideline/app.dart';
import 'package:rideline/services/app_state.dart';

/// End-to-end smoke test of the demo path's first steps:
/// login screen -> wrong password -> correct login -> dashboard.
void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppState(today: DateTime(2026, 10, 21)),
        child: const RideLineApp(),
      ),
    );
  }

  testWidgets('wrong password shows an error', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('login_email')), 'organizer@rideline.uz');
    await tester.enterText(find.byKey(const Key('login_password')), 'nope');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pump();
    expect(find.text('Wrong email or password.'), findsOneWidget);
  });

  testWidgets('demo login opens the dashboard with license warning', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byKey(const Key('login_email')), 'organizer@rideline.uz');
    await tester.enterText(find.byKey(const Key('login_password')), 'demo123');
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.textContaining('license expires in'), findsOneWidget); // NFR-04
    expect(find.text('Open seats'), findsOneWidget);
  });
}
