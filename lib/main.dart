import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/app_state.dart';

/// RideLine - CS363 midterm prototype (Team Bonjour).
///
/// Run with:  flutter run -d chrome
/// Demo login: organizer@rideline.uz / demo123
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const RideLineApp(),
    ),
  );
}
