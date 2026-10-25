# Architecture (prototype)

```
┌──────────────┐    watch / read     ┌──────────────────┐    uses    ┌─────────────────────┐
│   screens/   │ ──────────────────▶ │ AppState         │ ─────────▶ │ InvoiceService      │
│   widgets/   │ ◀── notifyListeners │ (ChangeNotifier) │            │ ComplianceService   │
└──────────────┘                     │  in-memory data  │            │ NotificationService │
        │                            └──────────────────┘            │ TrackingSimulator   │
        │ go(tab)                             ▲                       └─────────────────────┘
        ▼                                     │ seeded by
┌──────────────┐                     ┌──────────────────┐
│ NavController│                     │ MockData         │
└──────────────┘                     └──────────────────┘
```

- **State management:** [`provider`](https://pub.dev/packages/provider). One `AppState` object holds all data and is
  provided above `MaterialApp`. Screens call `context.watch<AppState>()` to rebuild when data changes.
- **Business logic lives in `services/`** and has no Flutter widgets, so it is easy to unit-test
  (`InvoiceService`, `ComplianceService`, `TrackingSimulator`, `NotificationService`).
- **Navigation:** a side menu (wide screens) or drawer (phones) switches between pages via `NavController`.
  Screens can open another page focused on a route, e.g. *Dashboard → Track*.
- **Map:** [`flutter_map`](https://pub.dev/packages/flutter_map) with OpenStreetMap tiles (no API key).
  `SchematicMap` is a drawn fallback that works offline.
- **Data:** generated relative to today's date so the demo always has current bookings, a license that expires in
  21 days, and a driver who is over the hours limit.

## Moving to the final version
| Prototype | Final |
|-----------|-------|
| `MockData` in memory | REST API + database (e.g. Firebase / Supabase / Node + PostgreSQL) |
| Hardcoded login | Real organizer accounts, hashed passwords, sessions |
| `TrackingSimulator` | GPS from a driver device / vehicle tracker; keep last location 5 min (NFR-02) |
| `NotificationService` builds messages only | SMS gateway (e.g. Eskiz.uz) + SMTP email |
| Invoice button | Scheduled job at end of billing period |
| — | Encryption at rest and in transit (NFR-01) |
| — | Monthly ridership report (FR-05) |

Because screens only talk to `AppState`, we can swap its internals for API calls without rewriting the UI.
