# RideLine 🚌 — Midterm Prototype

**CS363 Software Project Management · Team Bonjour**

RideLine is an app for company shuttle programs, built **for organizers only** (HR / facilities admins).
Organizers set up routes, book seats for employees, assign drivers, track shuttles live, and handle
billing and driver-compliance records. Riders never log in — they just get a text/email before the shuttle arrives.

This repository is the **midterm prototype**: one complete organizer path running on sample data.
The full app (real backend, real GPS, real SMS) comes in the final.

---

## ▶️ How to run

Requirements: [Flutter](https://docs.flutter.dev/get-started/install) 3.22 or newer.

```bash
git clone <this-repo-url>
cd rideline
flutter pub get
flutter run -d chrome          # runs in the browser (recommended for the demo)
```

Want Android / iOS / Windows too? Generate the platform folders once (it does not touch `lib/` or `test/`):

```bash
flutter create . --project-name rideline --org uz.newuu
```

Run the tests:

```bash
flutter test
```

**Demo login:** `organizer@rideline.uz` / `demo123` (or press **“Use demo account”**).

---

## ✅ What the prototype covers

| # | Screen | Requirement(s) | Where |
|---|--------|----------------|-------|
| 1 | Organizer login (hardcoded account) | — | `lib/screens/login_screen.dart` |
| 2 | Dashboard: today's shuttles, open seats, **license expiry warning** | FR-01, FR-02, **NFR-04** | `lib/screens/dashboard_screen.dart` |
| 3 | Routes: create a route with stops, dates and times; list of routes | **FR-01** | `routes_screen.dart`, `route_form_screen.dart` |
| 4 | Seat booking: book, change, cancel; cancelled seat shows as **available again** | **FR-02**, **FR-03** | `bookings_screen.dart` |
| 5 | Driver assignment: assign or switch a driver | **FR-04** | `drivers_screen.dart` |
| 6 | Driver hours log with **legal-limit warnings** | **FR-07**, **NFR-03** | `hours_screen.dart` |
| 7 | Invoice generated from bookings (button-triggered) | **FR-06** | `invoices_screen.dart` |
| 8 | Live tracking map with a moving shuttle + rider notifications | FR-08 (simulated) | `tracking_screen.dart` |

Full mapping to Jira tickets and tests: [`docs/REQUIREMENTS_TRACEABILITY.md`](docs/REQUIREMENTS_TRACEABILITY.md)

### Faked on purpose (prototype)
- **Live location** – a simulated GPS feed moves the marker along the route (there is no driver app yet).
- **Rider text/email (FR-08)** – messages are built and shown on screen as “sent”; nothing leaves the app.
- **Data** – sample routes, employees and drivers are stored in memory (`lib/data/mock_data.dart`) and reset on reload.
- **Encryption (NFR-01)** – cannot be shown visually; the plan is in [`docs/SECURITY_NOTES.md`](docs/SECURITY_NOTES.md).

### Left out for now
Monthly ridership report (FR-05) · 5-minute last-known-location memory (NFR-02) · real payments · rider/driver accounts.

---

## 🗂 Project structure

```
lib/
├── main.dart                 # entry point
├── app.dart                  # MaterialApp, login gate
├── theme/app_theme.dart      # colors & styles (Design)
├── models/                   # ShuttleRoute, Stop, Booking, Driver, Employee, Invoice, ...
├── data/mock_data.dart       # sample data (generated relative to today)
├── services/                 # app state + business logic (no UI)
│   ├── app_state.dart        # single source of truth (ChangeNotifier)
│   ├── auth_service.dart
│   ├── compliance_service.dart   # NFR-03 legal limits
│   ├── invoice_service.dart      # FR-06
│   ├── notification_service.dart # FR-08 (simulated)
│   ├── tracking_simulator.dart   # simulated GPS
│   └── nav_controller.dart
├── screens/                  # one file per screen
├── widgets/                  # reusable UI pieces
└── utils/format.dart         # dates, money
test/                         # unit + widget tests
docs/                         # demo script, traceability, test plan, team split, ...
```

More detail: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

---

## 👥 Team

| Member | Role | Owns |
|--------|------|------|
| Laylo Xoshimboyeva | Project Manager | Routes feature, README, demo script, traceability |
| Gulyuz Ibragimova | QA / Tester | Tests, test plan, driver-hours screen |
| Samira Jamolxonova | Design | Theme, widgets, login, dashboard, booking UI |
| Nozimjon Avazmurotov | DevOps | Models, data, services, tracking, invoices, CI |

See [`docs/TEAM_SPLIT.md`](docs/TEAM_SPLIT.md) for the exact file list per person and the commit plan.

## 🎬 Demo

Follow [`docs/DEMO_SCRIPT.md`](docs/DEMO_SCRIPT.md) (about 5 minutes).
