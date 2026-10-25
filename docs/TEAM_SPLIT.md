# Team Split — who owns which files

Each person owns a slice of the prototype that matches their role. Ownership means: you can explain the file in
the presentation, you review changes to it, and the commit for it goes under your name.

## Laylo Xoshimboyeva — Project Manager
Feature: **Routes (FR-01)** and **Invoices (FR-06)** + project documentation
- `lib/screens/routes_screen.dart`
- `lib/screens/route_form_screen.dart`
- `lib/screens/invoices_screen.dart`
- `README.md`
- `docs/DEMO_SCRIPT.md`
- `docs/REQUIREMENTS_TRACEABILITY.md`
- `docs/TEAM_SPLIT.md`

## Samira Jamolxonova — Design
Feature: **visual style, login, dashboard (NFR-04 banner), seat booking UI (FR-02/03)**
- `lib/theme/app_theme.dart`
- `lib/widgets/app_card.dart`, `empty_state.dart`, `license_banner.dart`, `page_header.dart`,
  `requirement_tag.dart`, `responsive_grid.dart`, `schematic_map.dart`, `seat_bar.dart`,
  `stat_card.dart`, `status_pill.dart`
- `lib/screens/login_screen.dart`
- `lib/screens/home_shell.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/bookings_screen.dart`

## Gulyuz Ibragimova — QA / Tester
Feature: **driver compliance (FR-07, NFR-03), driver assignment (FR-04), all tests**
- `lib/services/compliance_service.dart`
- `lib/screens/hours_screen.dart`
- `lib/screens/drivers_screen.dart`
- `test/widget_test.dart`
- `test/services/booking_test.dart`
- `test/services/compliance_service_test.dart`
- `test/services/invoice_service_test.dart`
- `test/services/tracking_and_license_test.dart`
- `docs/TEST_PLAN.md`

## Nozimjon Avazmurotov — DevOps
Feature: **project setup, data layer, app state, live tracking + notifications (FR-08), CI**
- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`
- `web/index.html`, `web/manifest.json`
- `.github/workflows/flutter.yml`
- `lib/main.dart`, `lib/app.dart`
- `lib/models/*` (all model files)
- `lib/data/mock_data.dart`
- `lib/utils/format.dart`
- `lib/services/app_state.dart`, `auth_service.dart`, `invoice_service.dart`,
  `notification_service.dart`, `tracking_simulator.dart`, `nav_controller.dart`
- `lib/screens/tracking_screen.dart`
- `docs/ARCHITECTURE.md`, `docs/SECURITY_NOTES.md`
- `scripts/commit_as_team.sh`

---

## Pushing it (one person pushes, commits keep each author)

1. Create an empty repo on GitHub (no README), e.g. `rideline`.
2. Open `scripts/commit_as_team.sh` and put each member's **GitHub email** at the top
   (so each commit shows on their GitHub profile).
3. Run from the project folder:

```bash
bash scripts/commit_as_team.sh
git remote add origin https://github.com/<your-account>/rideline.git
git push -u origin main
```

The script makes ~15 small commits in a sensible order (setup → models → design → services → screens → tests → docs),
each one with the owner as the author. Run `git log --oneline` to check.

> After the midterm, everyone should work on their own branch (`feature/<name>-<thing>`) and open pull requests,
> so the history keeps reflecting real contributions.
