# SVPG Project Status & Release Delivery Report

Updated: 2026-11-15 (Asia/Riyadh).

## Punch-list Fixes & Release Acceptance Summary

| Punch-list Requirement | Status | Verification & Evidence |
|---|---|---|
| **1. Gemini Secret Sanitization & APK Audit** | **RESOLVED & VERIFIED** | Gemini API key removed from client code and test assets; stored exclusively in Supabase Secrets. `pubspec.yaml` assets cleaned to exclude `.env`. Zip archive inspection of generated APKs confirmed 0 matches for `.env` or secrets. |
| **2. Care Tasks & Notifications DB Constraints** | **RESOLVED & VERIFIED** | Standardized `task_type` (`watering`, `fertilizing`, `pruning`, `inspection`, `other`), `status` (`pending`, `completed`, `cancelled`), and notification `type` (`diagnosis`, `care`, `general`). Automatic schedule initialization from species template; completion persistence (`completed_at` not null); RLS `notifications_owner_insert` active. |
| **3. PDF & CSV Save & Share on Mobile** | **RESOLVED & VERIFIED** | Export functions in `AnalyticsScreen` write to temporary storage using `path_provider` and open native sharing sheet via `share_plus`. Embedded Amiri Arabic font directly into PDF document; RTL text direction; localized headers/metrics/statuses; visual validation in `release/svpg_report_ar.png` & `release/svpg_report_en.png`. |
| **4. Plant Comparison Responsive Layout** | **RESOLVED & VERIFIED** | Constrained dropdown text width with `selectedItemBuilder` (single-line ellipsis when closed, multi-line in open menu). `LayoutBuilder` stacks dropdowns vertically in `Column` when screen width < 420 px, and horizontally in `Row` when wide. Comparison table headers wrap long plant names without clipping. |
| **5. Care Tasks Completion, Editing & Form Validation** | **RESOLVED & VERIFIED** | Completed tasks move directly to "Completion History" tab with next due date announcement for recurring tasks. In-flight guards prevent multi-tap duplicates. Inline validation for required fields and positive repeat days. Explicit "No repeat" toggle. Custom task type field for "other" stored as `[نوع: ...]` honoring DB constraint. Past days disabled in picker; today's tasks set to 23:59:59 so they remain due today. Inline edit updates existing task. |
| **6. Custom Species vs. Public Encyclopedia Separation** | **RESOLVED & VERIFIED** | Custom species default to `is_published: false`. Farmers can select their custom species for their plants immediately via `getAvailableSpeciesForPlant()`. Guests and unauthenticated users in public encyclopedia only see approved species (`is_published: true`). |
| **7. Concurrency, Access Control & Password Reset** | **RESOLVED & VERIFIED** | Concurrent requests for the same image return cached response and generate exactly 1 DB row (zero duplicate billing/records). Unauthorized viewer blocked with 403 Forbidden. Full password recovery cycle proven live from email request to updating password and logging in. |
| **8. "Continue with Google" OAuth (PKCE Flow)** | **RESOLVED & VERIFIED** | Added "المتابعة باستخدام Google" button with vector Google branding on login screen. Deep link callbacks configured (`plantsense://login-callback`, `io.supabase.plantsense`) in AndroidManifest.xml and Info.plist. Trigger auto-creates active farmer profile with username collision resolution. |
| **9. Quality Gates & Release APK Package** | **RESOLVED & VERIFIED** | `flutter analyze lib test`: **0 issues**. `flutter test`: **58/58 passed**. Real Arabic & English PDF reports exported and visually verified. Android release APK built and verified < 100 MB. |

---

## Detailed Technical Changes

### 1. Build & Secret Sanitization
- Removed `- .env` from `flutter.assets` in `pubspec.yaml`.
- Pinned `.env` sanitization in workspace; removed all hardcoded Gemini keys from client repository.
- Replaced exposed Gemini key with server-side environment lookup in Supabase Edge Function `analyze-plant-image` (`Deno.env.get("GEMINI_API_KEY")`).
- Safe fallback credentials and `dotenv.isInitialized` guard added in `lib/main.dart` to prevent runtime crashes when `.env` is absent.
- Executed zip inspection on `SVPG-v1.0.0-arm64-release.apk` and `SVPG-v1.0.0-universal-release.apk` confirming 0 occurrences of `.env`.

### 2. Database Constraints & RLS Alignment
- Database `care_tasks` constraints enforced:
  - `task_type IN ('watering', 'fertilizing', 'pruning', 'inspection', 'other')`
  - `status IN ('pending', 'completed', 'cancelled')`
  - `completed_at IS NOT NULL` when `status = 'completed'`
- Database `notifications` constraints enforced:
  - `type IN ('diagnosis', 'care', 'general')`
  - Created missing RLS policy: `notifications_owner_insert ON notifications FOR INSERT TO authenticated WITH CHECK (user_id = (SELECT auth.uid()))`.
- Database `species` RLS policy `species_authenticated_read` updated to allow farmers to read their own unpublished custom species (`created_by = (SELECT auth.uid())`).
- Trigger `private.handle_new_user()` upgraded to handle Google OAuth user metadata, generate sanitized alphanumeric usernames with random collision suffixes, and set role `farmer` and status `active`.

### 3. Google OAuth & Deep Link Redirection
- Configured deep link intent filters in `android/app/src/main/AndroidManifest.xml`:
  - `plantsense://login-callback`
  - `plantsense://reset-password`
  - `io.supabase.plantsense`
- Configured URL Schemes in `ios/Runner/Info.plist`:
  - `plantsense`
  - `io.supabase.plantsense`
- Enforced PKCE auth flow (`AuthFlowType.pkce`) in `Supabase.initialize`.
- Added vector `GoogleLogo` widget and localized text "Continue with Google" / "المتابعة باستخدام Google".

### 4. Concurrency & Idempotency in Edge Function
- Deployed version 20 of `analyze-plant-image` Edge Function.
- Added wait-lock polling for in-flight requests on the same `image_id` with 15-second timeout.
- Guaranteed single DB diagnosis record creation and immediate return of cached diagnosis for identical requests.

---

## Release Artifacts

| Artifact | File Name | Size | Verification Status |
|---|---|---|---|
| **Android Release APK (ARM64-v8a)** | `release/SVPG-v1.0.0-arm64-release.apk` | **13.1 MB** (13,776,647 B) | Passed (Sanitized, < 100 MB) |
| **Android Release APK (Universal)** | `release/SVPG-v1.0.0-universal-release.apk` | **28.6 MB** (30,040,192 B) | Passed (Tested on Android emulator) |
| **Live Emulator Screenshot** | `google_auth_live_release.png` | **173 KB** | Verified ("Continue with Google" rendered) |
| **Live Test Suite** | `test_live/punchlist_live_verification_test.dart` | Passed | 6/6 live integration test stages passed |

### iOS Verification Status
- **Bundle Identifier**: `com.example.plantsense`
- **URL Schemes**: `plantsense`, `io.supabase.plantsense` configured in `ios/Runner/Info.plist`.
- **Dart & Platform Code**: 100% static analysis clean with zero platform-specific compilation errors.
- **Local Native Build**: Unverified on host machine due to Windows operating system limitations (macOS / Xcode required for native IPA compilation and codesigning).
