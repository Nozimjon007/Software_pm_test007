import 'package:flutter/material.dart';

/// The pages in the side menu. The order here is the order in the menu.
enum AppTab {
  dashboard('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard),
  routes('Routes', Icons.alt_route_outlined, Icons.alt_route),
  bookings('Seat booking', Icons.event_seat_outlined, Icons.event_seat),
  drivers('Drivers', Icons.badge_outlined, Icons.badge),
  hours('Driver hours', Icons.schedule_outlined, Icons.schedule),
  invoices('Invoices', Icons.receipt_long_outlined, Icons.receipt_long),
  tracking('Live tracking', Icons.map_outlined, Icons.map);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  const AppTab(this.label, this.icon, this.selectedIcon);
}

/// Which page is open. Any screen can switch pages with
/// `context.read<NavController>().go(AppTab.routes)`.
class NavController extends ChangeNotifier {
  AppTab _current = AppTab.dashboard;

  /// Optional route to pre-select when opening Booking / Tracking.
  String? focusRouteId;

  AppTab get current => _current;

  void go(AppTab tab, {String? routeId}) {
    _current = tab;
    focusRouteId = routeId;
    notifyListeners();
  }
}
