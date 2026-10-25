# Demo Script (≈ 5 minutes)

**Goal:** show one complete organizer path that covers all Must Have requirements.
Run with `flutter run -d chrome` on a laptop screen (wide layout). Practise it at least twice.

> Tip: reload the app (press `R` in the terminal) right before presenting — the sample data resets.

| Step | What you do | What you say | Req |
|------|-------------|--------------|-----|
| 1 | Open the app → press **Use demo account** → **Sign in** | “Only organizers log in. Riders and drivers don't have accounts.” | — |
| 2 | On the **Dashboard**, point at the amber banner | “RideLine keeps our passenger-transport license on file and warns us 30 days before it expires.” Click **Details**. | NFR-04 |
| 3 | Point at the KPI cards and shuttle cards | “Today's shuttles, riders booked and open seats at a glance. The Sergeli route has no driver yet.” | FR-01/02 |
| 4 | **Routes** → **New route**. Name: `Beruniy → Tashkent City Office`. Stop 1: *Beruniy metro* 07:40, press **Add stop** → *Chorsu bazaar* 08:10 (the last stop is pre-filled: *Tashkent City Office* 08:30). Press **Create route** | “Organizers create routes with stops, dates and times.” Show it in the list. | FR-01 |
| 5 | **Seat booking** → choose *Chilonzor → Tashkent City Office*. Tap a **free seat** → pick *Ulugbek Sobirov* → **Book seat** | “We book a seat for an employee.” Seat turns blue with initials. | FR-02 |
| 6 | Tap the same seat (or ✏️) → change the pickup stop → **Save changes** | “Bookings can be changed.” | FR-02 |
| 7 | Press ❌ next to the passenger → **Cancel seat** | “When a seat is cancelled it is freed immediately — the requirement is 60 seconds.” Point at the green **FREED** seat and the snackbar showing the milliseconds. | FR-03 |
| 8 | **Drivers** → on *Sergeli → Tashkent City Office* press **Assign** → choose *Jasur Tursunov*. Then **Switch** → choose *Bekzod Karimov* | “We can assign or switch a driver at any time.” A warning pops up: Bekzod is over the legal hours. | FR-04 |
| 9 | **Driver hours** | “Every driver's working and rest time is logged. Red cells break Uzbekistan's driver working-time rules.” Optionally **Log hours** → 11 h → warning appears. | FR-07, NFR-03 |
| 10 | **Invoices** → **Generate invoice** | “Invoices are created from bookings. In the final version this runs automatically at the end of each billing period; here we trigger it with a button. Cancelled seats are not billed.” | FR-06 |
| 11 | **Live tracking** → choose *Chilonzor* → **Start trip** → set speed **4×** | “The shuttle moves on the map. GPS is simulated because there is no driver app yet.” When it nears a stop, a **notification sent** message appears. | FR-08 |
| 12 | (Optional) switch **Map → Simple** | “Offline drawn view, works without internet.” | — |

## Closing line
“This prototype covers all Must Have requirements. Encryption (NFR-01) is not visible in a UI, so we documented
the plan. The final version adds the backend, real SMS/email, the ridership report and connection-loss handling.”

## If something goes wrong
- **Map tiles don't load (no internet):** switch to **Simple** view — same moving shuttle.
- **Weekend demo:** the dashboard automatically shows the *next service day* (shuttles run Mon–Fri).
- **Data looks messy after practising:** reload the app — all data resets.
