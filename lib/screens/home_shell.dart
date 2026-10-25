import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../services/nav_controller.dart';
import '../theme/app_theme.dart';
import 'bookings_screen.dart';
import 'dashboard_screen.dart';
import 'drivers_screen.dart';
import 'hours_screen.dart';
import 'invoices_screen.dart';
import 'routes_screen.dart';
import 'tracking_screen.dart';

/// App frame after login: side menu (wide screens) or drawer (phones)
/// plus the selected page.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NavController(),
      child: const _ShellBody(),
    );
  }
}

class _ShellBody extends StatelessWidget {
  const _ShellBody();

  Widget _page(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return const DashboardScreen();
      case AppTab.routes:
        return const RoutesScreen();
      case AppTab.bookings:
        return const BookingsScreen();
      case AppTab.drivers:
        return const DriversScreen();
      case AppTab.hours:
        return const HoursScreen();
      case AppTab.invoices:
        return const InvoicesScreen();
      case AppTab.tracking:
        return const TrackingScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    final tabs = AppTab.values;

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final page = KeyedSubtree(key: ValueKey(nav.current), child: _page(nav.current));

        if (wide) {
          return Scaffold(
            body: Row(
              children: [
                _SideMenu(current: nav.current, onSelect: nav.go),
                const VerticalDivider(width: 1),
                Expanded(child: page),
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(nav.current.label),
            actions: const [_UserButton()],
          ),
          drawer: Drawer(
            child: SafeArea(
              child: ListView(
                children: [
                  const Padding(padding: EdgeInsets.all(20), child: _Brand()),
                  for (final t in tabs)
                    ListTile(
                      leading: Icon(t == nav.current ? t.selectedIcon : t.icon),
                      title: Text(t.label),
                      selected: t == nav.current,
                      onTap: () {
                        nav.go(t);
                        Navigator.of(context).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
          body: page,
        );
      },
    );
  }
}

class _SideMenu extends StatelessWidget {
  final AppTab current;
  final void Function(AppTab tab, {String? routeId}) onSelect;

  const _SideMenu({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 24, 20, 24), child: _Brand()),
            for (final t in AppTab.values)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Material(
                  color: t == current ? AppColors.primary.withAlpha(22) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onSelect(t),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          Icon(
                            t == current ? t.selectedIcon : t.icon,
                            color: t == current ? AppColors.primary : AppColors.textMuted,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            t.label,
                            style: TextStyle(
                              fontWeight: t == current ? FontWeight.w700 : FontWeight.w500,
                              color: t == current ? AppColors.primary : const Color(0xFF34445A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const Spacer(),
            const Divider(height: 1),
            const Padding(padding: EdgeInsets.all(12), child: _UserButton(expanded: true)),
          ],
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.directions_bus_filled, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        const Text(
          'RideLine',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
        ),
      ],
    );
  }
}

class _UserButton extends StatelessWidget {
  final bool expanded;
  const _UserButton({this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final name = state.auth.currentUser ?? '';

    void confirmLogout() {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sign out?'),
          content: const Text('You will return to the login screen.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                state.logout();
              },
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
    }

    if (!expanded) {
      return IconButton(
        tooltip: 'Sign out',
        icon: const Icon(Icons.logout),
        onPressed: confirmLogout,
      );
    }

    return Row(
      children: [
        const CircleAvatar(
          radius: 18,
          backgroundColor: AppColors.primary,
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
              const Text('organizer@rideline.uz', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
        IconButton(tooltip: 'Sign out', icon: const Icon(Icons.logout, size: 20), onPressed: confirmLogout),
      ],
    );
  }
}
