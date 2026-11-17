# SVPG Project Status & Release Delivery Report

Updated: 2026-11-17 (Asia/Riyadh).

## Final Release Delivery Fixes & Acceptance Summary

| Requirement & Area | Status | Verification & Evidence |
|---|---|---|
| **1. Registration Pre-request Client Validation & Error Mapping** | **RESOLVED & VERIFIED** | Added client-side validations for full name, username alphanumeric format (min 3 chars), email regex, password min length (6 chars), and confirmation match. Intercepts empty submission with localized amber warning before making any network call, preventing raw Supabase 422 errors. Mapped `AuthException` duplicate username and network socket errors to clear localized notifications. 7/7 tests passing in `test/register_screen_test.dart` and visually confirmed on live device. |
| **2. Analytics Zero State & Responsive Comparison** | **RESOLVED & VERIFIED** | When `totalInspections == 0`, displays "لا توجد فحوصات" / "No inspections" with auto-scaled font instead of false 100%. Displays "0%" when inspections exist but none are healthy. Both CSV and PDF exports reflect "لا توجد فحوصات" / "No inspections" accurately. Plant comparison dropdowns and comparison table wrap gracefully on narrow mobile screens (Pixel 7 Pro) without overflow in both Arabic and English. |
| **3. Language Switching In-Place Retention** | **RESOLVED & VERIFIED** | Replaced inline `GoRouter` instantiation in `SVPGApp` with a single cached router instance in state. Switching language toggles locale and updates all UI strings and RTL/LTR layout immediately without rebuilding `GoRouter` or redirecting the user back to `/`. Active form inputs (e.g. registration, task form, analytics filters) remain intact. Locale persisted in `SharedPreferences` with default Arabic (`ar`) on first launch. |
| **4. Care Schedule Recurring Default & Lineage** | **RESOLVED & VERIFIED** | "Add Care Task" form opens with `isRecurring` toggle **OFF** by default ("بدون تكرار (مهمة لمرة واحدة)"). One-time tasks complete into history without scheduling a future task. Recurring tasks create exactly one next due date. Inline date validation rejects past dates for new tasks (`isBefore(todayStart)`), while existing past tasks show as "متأخرة" (Overdue). Selecting "other" enforces custom task type name stored as `[نوع: ...]`. |
| **5. Search & Agricultural Encyclopedia Content** | **RESOLVED & VERIFIED** | Plant search query updated to `name.ilike.%$s%,location.ilike.%$s%`, enabling plant filtering by name OR field location. Updated species database records with comprehensive Arabic descriptions and vertical care guidelines (Bell Pepper, Lettuce, Strawberry, Spearmint, Basil, Tomato). System notifications localized in Arabic and English. |
| **6. Secret Sanitization & Quality Gates** | **RESOLVED & VERIFIED** | `.env` and hardcoded API keys completely excluded from APK assets (`pubspec.yaml` clean). `flutter analyze lib test`: **0 issues**. Full test suite `flutter test`: **75/75 tests passed**. ARM64 Release APK built at **13.74 MB** (< 100 MB ceiling) and verified live on Pixel 7 Pro (API 31 emulator). |

---

## Technical Changes Details

### 1. Registration (`lib/screens/register_screen.dart` & `test/register_screen_test.dart`)
- Added comprehensive pre-network validations:
  - Full Name: required, minimum 2 characters.
  - Username: required, alphanumeric + underscore only, minimum 3 characters.
  - Email: RFC-compliant email regex.
  - Password: minimum 6 characters.
  - Confirm Password: exact match check.
- Added graceful error mapping for Supabase `AuthException` (code 422, duplicate username/email, code 429 rate limit) and network `SocketException`/`TimeoutException`.
- Integrated `ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(...)` for responsive feedback.

### 2. Analytics (`lib/screens/analytics/analytics_screen.dart` & `lib/services/analytics_service.dart`)
- Fixed health KPI logic:
  - If `totalInspections == 0` -> displays localized string "لا توجد فحوصات" / "No inspections".
  - If `totalInspections > 0 && totalHealthy == 0` -> displays "0%".
- CSV export outputs "لا توجد فحوصات" / "No inspections" under the "سليم" column when inspections are 0.
- PDF export `localizeStatus` maps 0 inspections to "لا توجد فحوصات" / "No inspections".
- Localized species names integrated into `PlantAnalyticsSummary` using `LocaleService.isArabic`.

### 3. Locale Management (`lib/main.dart` & `lib/services/locale_service.dart`)
- `SVPGApp` state stores `_router = createRouter(widget.authService);` created once in `initState()`.
- Language switching updates `LocaleService.localeNotifier` which triggers `MaterialApp.router` rebuild without recreating router routes or state.
- Locale persisted to `SharedPreferences` under key `app_language_code`.

### 4. Care Schedule (`lib/screens/plants/care_tasks_screen.dart` & `lib/services/care_task_service.dart`)
- `isRecurring` defaults to `false` for new tasks. Repeat days input hidden until recurring is toggled on.
- Validates that new tasks cannot have due dates in the past.
- Single next-occurrence scheduling logic enforces lineage via `original_task_id` preventing task duplication.

### 5. Species Localization & Search (`lib/models/species.dart`, `lib/models/plant.dart`, `lib/services/plant_service.dart`)
- Added `localizedName`, `localizedDescription`, `localizedCareInstructions` to `Species`.
- Added `localizedSpeciesName` to `Plant`.
- Multi-column search with `.or('name.ilike.%$s%,location.ilike.%$s%')` in `PlantService.getPlants`.

---

## Release Artifacts

| Artifact | File Path | Size | Verification Status |
|---|---|---|---|
| **Android Release APK (ARM64-v8a)** | `release/SVPG-v1.0.0-arm64-release.apk` | **13.74 MB** (14,409,963 B) | Verified on Pixel 7 Pro (API 31), Sanitized (< 100 MB) |
| **Arabic PDF Report** | `release/svpg_report_ar.pdf` | **14.2 KB** | Embedded Amiri Arabic font, RTL, Verified |
| **English PDF Report** | `release/svpg_report_en.pdf` | **14.1 KB** | Clean LTR layout, Metrics verified |
| **Live Emulator Evidence** | Artifact directory PNGs | ~180 KB each | 14 live screenshots covering Auth, Language, Analytics, Search, Care |
| **Quality Verification** | `flutter analyze` & `flutter test` | 75/75 passed | 0 analyzer issues, 100% test pass rate |
