# Test Plan — Midterm Prototype

**Owner:** Gulyuz Ibragimova (QA / Tester)

## Automated tests
Run `flutter test`.

| File | Covers |
|------|--------|
| `test/services/booking_test.dart` | FR-01 create route · FR-02 book / change / double-booking / full shuttle · FR-03 seat freed · FR-04 assign / switch / warning |
| `test/services/compliance_service_test.dart` | FR-07, NFR-03 daily, weekly and rest limits |
| `test/services/invoice_service_test.dart` | FR-06 billing period, cancelled seats not billed, VAT |
| `test/services/tracking_and_license_test.dart` | Simulated GPS movement · FR-08 messages · NFR-04 30-day warning |
| `test/widget_test.dart` | Login error, login → dashboard, license banner visible |

## Manual test cases

| ID | Req | Steps | Expected | Result |
|----|-----|-------|----------|--------|
| TC-01 | — | Login with wrong password | “Wrong email or password.” shown | ☐ |
| TC-02 | — | Login with demo account | Dashboard opens | ☐ |
| TC-03 | NFR-04 | Look at dashboard | Amber banner: license expires in 21 days | ☐ |
| TC-04 | FR-01 | Create route with 3 stops | Route appears in list with stops & times | ☐ |
| TC-05 | FR-01 | Create route with stop times out of order | Error “Stop 2 must be later than stop 1.” | ☐ |
| TC-06 | FR-01 | Create route without a name | Validation error on name field | ☐ |
| TC-07 | FR-02 | Book a free seat for an employee | Seat becomes blue with initials, passenger listed | ☐ |
| TC-08 | FR-02 | Book an employee who already has a seat that day | Not offered in list / error shown | ☐ |
| TC-09 | FR-02 | Change pickup stop of a booking | Passenger list shows the new stop | ☐ |
| TC-10 | FR-03 | Cancel a booking | Seat shows “FREED”, snackbar shows release time < 60 s | ☐ |
| TC-11 | FR-03 | Book the freed seat for someone else | Booking succeeds | ☐ |
| TC-12 | FR-04 | Assign driver to Sergeli route | Driver shown, “No driver” badge disappears on dashboard | ☐ |
| TC-13 | FR-04 | Switch to Bekzod Karimov | Warning dialog: over legal limit | ☐ |
| TC-14 | FR-07 | Open Driver hours | Table with hours per driver per day | ☐ |
| TC-15 | NFR-03 | Log 11 h for a driver | Cell turns red, warning banner updates | ☐ |
| TC-16 | FR-06 | Generate invoice | Invoice with route lines, subtotal, VAT 12%, total | ☐ |
| TC-17 | FR-06 | Cancel a seat, generate invoice again | Seat count is one lower | ☐ |
| TC-18 | FR-08 | Start trip on Live tracking | Marker moves; “Notification sent” appears near stops | ☐ |
| TC-19 | — | Switch Map → Simple | Drawn route with moving shuttle | ☐ |
| TC-20 | — | Resize window to phone width | Menu becomes a drawer, no overflow | ☐ |

## Bug log
| # | Found by | Screen | Description | Severity | Status |
|---|----------|--------|-------------|----------|--------|
| 1 | | | | | |
