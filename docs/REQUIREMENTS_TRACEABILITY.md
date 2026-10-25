# Requirements Traceability Matrix

Links every requirement from the *Midterm Requirements Document (Week 2)* to the prototype screen, the code and the tests.
Replace `RL-?` with your real Jira keys.

| ID | Priority | Requirement | Prototype status | Screen | Code | Test | Jira |
|----|----------|-------------|------------------|--------|------|------|------|
| FR-01 | Must | Create and manage shuttle routes — stops, dates, times | ✅ Built | Routes, New route | `screens/routes_screen.dart`, `screens/route_form_screen.dart`, `AppState.addRoute/deleteRoute` | `booking_test.dart` › *FR-01* | RL-? |
| FR-02 | Must | Book, change, or cancel a seat for an employee | ✅ Built | Seat booking | `screens/bookings_screen.dart`, `AppState.bookSeat/changeBooking/cancelBooking` | `booking_test.dart` › *FR-02* | RL-? |
| FR-03 | Should | Cancelled seat freed within 60 seconds | ✅ Built (instant, shows “FREED”) | Seat booking | `AppState.cancelBooking`, `seatReleasedAt` | `booking_test.dart` › *FR-03* | RL-? |
| FR-04 | Should | Assign or switch a driver at any time | ✅ Built | Drivers | `screens/drivers_screen.dart`, `AppState.assignDriver` | `booking_test.dart` › *FR-04* | RL-? |
| FR-05 | Should | Monthly ridership report | ⏭ Final version | — | — | — | RL-? |
| FR-06 | Must | Invoice at end of billing period | ✅ Built (button-triggered) | Invoices | `services/invoice_service.dart`, `screens/invoices_screen.dart` | `invoice_service_test.dart` | RL-? |
| FR-07 | Must | Record of driver working hours | ✅ Built | Driver hours | `screens/hours_screen.dart`, `AppState.logHours` | `compliance_service_test.dart` | RL-? |
| FR-08 | Should | Riders get text/email 10 min before arrival | 🟡 Simulated (shown on screen) | Live tracking | `services/notification_service.dart`, `screens/tracking_screen.dart` | `tracking_and_license_test.dart` › *FR-08* | RL-? |
| NFR-01 | Must | Rider & payment data encrypted (stored + in transit) | 📄 Documented plan | — | see `docs/SECURITY_NOTES.md` | — | RL-? |
| NFR-02 | Should | Remember last known location for 5 min | ⏭ Final version | — | — | — | RL-? |
| NFR-03 | Must | Driver hours logged per Uzbekistan rules | ✅ Built (warnings) | Driver hours, Drivers, Dashboard | `services/compliance_service.dart` | `compliance_service_test.dart` | RL-? |
| NFR-04 | Must | License on file + warning before expiry | ✅ Built | Dashboard banner | `models/transport_license.dart`, `widgets/license_banner.dart` | `widget_test.dart`, `tracking_and_license_test.dart` › *NFR-04* | RL-? |

Every screen also shows its requirement IDs as small blue tags next to the page title.
