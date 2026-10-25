import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';

class RideLineApp extends StatelessWidget {
  const RideLineApp({super.key});

  @override
  Widget build(BuildContext context) {
    final loggedIn = context.select<AppState, bool>((s) => s.auth.isLoggedIn);

    return MaterialApp(
      title: 'RideLine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: loggedIn ? const HomeShell() : const LoginScreen(),
    );
  }
}
