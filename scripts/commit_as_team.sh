#!/usr/bin/env bash
# Creates the initial Git history with each file committed under its owner's name.
# See docs/TEAM_SPLIT.md. Run once, from the project root:  bash scripts/commit_as_team.sh
set -euo pipefail

# ---- 1. Fill in each member's GitHub email (the one on their GitHub account) ----
LAYLO="Laylo Xoshimboyeva <laylo@example.com>"
SAMIRA="Samira Jamolxonova <samira@example.com>"
GULYUZ="Gulyuz Ibragimova <gulyuz@example.com>"
NOZIMJON="Nozimjon Avazmurotov <nozimjon@example.com>"
# ---------------------------------------------------------------------------------

cd "$(dirname "$0")/.."

if [[ "$LAYLO$SAMIRA$GULYUZ$NOZIMJON" == *"@example.com"* ]]; then
  echo "⚠  Edit the emails at the top of scripts/commit_as_team.sh first."
  read -r -p "Continue with placeholder emails anyway? [y/N] " ans
  [[ "$ans" == "y" || "$ans" == "Y" ]] || exit 1
fi

if [ ! -d .git ]; then
  git init -b main
fi

c() { # c "<author>" "<message>" files...
  local author="$1"; local msg="$2"; shift 2
  git add -- "$@"
  if git diff --cached --quiet; then
    echo "skip (nothing new): $msg"
  else
    git commit --quiet --author="$author" -m "$msg"
    echo "✓ $msg  — ${author%% <*}"
  fi
}

c "$NOZIMJON" "chore: project setup (pubspec, lint rules, web shell, gitignore)" \
  pubspec.yaml analysis_options.yaml .gitignore web/index.html web/manifest.json

c "$NOZIMJON" "ci: GitHub Actions workflow for analyze, test and web build" \
  .github/workflows/flutter.yml

c "$NOZIMJON" "feat(models): routes, stops, bookings, drivers, employees, invoices, license" \
  lib/models

c "$NOZIMJON" "feat(data): sample data and formatting helpers" \
  lib/data/mock_data.dart lib/utils/format.dart

c "$SAMIRA" "design: RideLine theme and colour palette" \
  lib/theme/app_theme.dart

c "$SAMIRA" "design: reusable widgets (cards, header, requirement tags, pills, seat bar, license banner)" \
  lib/widgets

c "$NOZIMJON" "feat(services): app state, auth, invoices, notifications, GPS simulator, navigation" \
  lib/services/app_state.dart lib/services/auth_service.dart lib/services/invoice_service.dart \
  lib/services/notification_service.dart lib/services/tracking_simulator.dart lib/services/nav_controller.dart

c "$GULYUZ" "feat(compliance): driver working-time limits (FR-07, NFR-03)" \
  lib/services/compliance_service.dart

c "$SAMIRA" "feat(ui): organizer login, app shell and dashboard with license warning (NFR-04)" \
  lib/screens/login_screen.dart lib/screens/home_shell.dart lib/screens/dashboard_screen.dart

c "$LAYLO" "feat(routes): route list and create-route form (FR-01)" \
  lib/screens/routes_screen.dart lib/screens/route_form_screen.dart

c "$SAMIRA" "feat(booking): seat map, book / change / cancel, freed seats (FR-02, FR-03)" \
  lib/screens/bookings_screen.dart

c "$GULYUZ" "feat(drivers): assign and switch drivers, hours log with warnings (FR-04, FR-07)" \
  lib/screens/drivers_screen.dart lib/screens/hours_screen.dart

c "$LAYLO" "feat(invoices): generate invoice from bookings (FR-06)" \
  lib/screens/invoices_screen.dart

c "$NOZIMJON" "feat(tracking): live map with simulated GPS and rider alerts (FR-08); app entry point" \
  lib/screens/tracking_screen.dart lib/main.dart lib/app.dart

c "$GULYUZ" "test: unit and widget tests for booking, compliance, invoices, tracking, login" \
  test

c "$GULYUZ" "docs: test plan and manual test cases" \
  docs/TEST_PLAN.md

c "$NOZIMJON" "docs: architecture and security (NFR-01) notes; team commit script" \
  docs/ARCHITECTURE.md docs/SECURITY_NOTES.md scripts/commit_as_team.sh

c "$LAYLO" "docs: README, demo script, requirements traceability, team split" \
  README.md docs/DEMO_SCRIPT.md docs/REQUIREMENTS_TRACEABILITY.md docs/TEAM_SPLIT.md

# Anything left over (e.g. platform folders from `flutter create .`)
git add -A
if ! git diff --cached --quiet; then
  git commit --quiet --author="$NOZIMJON" -m "chore: platform folders and remaining files"
  echo "✓ chore: platform folders and remaining files"
fi

echo
git log --oneline --format='%h  %<(22)%an %s'
echo
echo "Done. Now: git remote add origin <repo-url> && git push -u origin main"
