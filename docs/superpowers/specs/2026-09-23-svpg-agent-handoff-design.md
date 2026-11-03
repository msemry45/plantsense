# SVPG Developer Handoff & System Design

Status: Approved implementation baseline  
Audience: Autonomous coding agent and human reviewer  
Product: Smart Vertical Plant Growth Monitoring (SVPG)  
Platforms: Android and iOS through one Flutter codebase  
Project window: 18 September 2026 to 20 November 2026

## 1. Arabic Owner Summary

هذه الوثيقة هي المرجع المباشر لأي Agent سيبرمج تطبيق SVPG. النسخة الأولى تطبيق Flutter يتيح للمستخدم تسجيل نباتاته، التقاط صورة أو اختيارها يدويًا من المعرض، إرسالها عبر Supabase Edge Function إلى نموذج ذكاء اصطناعي جاهز، ثم عرض نتيجة عامة وحفظها في سجل النبات. لا يوجد في النسخة الأولى بث مباشر، كاميرا IoT، حساسات، ري آلي، أو تدريب نموذج خاص. على الـAgent تنفيذ المشروع Milestone بعد Milestone، وتشغيل الاختبارات وتسليم أدلة القبول قبل الانتقال للمرحلة التالية.

## 2. Instruction Authority

When sources conflict, obey this order:

1. This handoff document.
2. `PlantSense Product Requirements Document.docx`.
3. `PlantSense Implementation Plan.pdf` and `.gan` for milestone order and dates.
4. `PLANTSENSE MONITORING SYSTEM.docx` for academic background only.

Any older thesis statement requiring a live camera, IoT hardware, environmental sensors, actuators, or custom model training is superseded for V1.

## 3. Agent Operating Contract

The coding agent MUST:

- Work one milestone at a time and stop after its exit gate.
- Read existing repository instructions and preserve unrelated user changes.
- Prefer the smallest Flutter/Supabase implementation that satisfies acceptance criteria.
- Keep AI provider credentials exclusively in server-side secrets.
- Enforce permissions in both UI and Supabase RLS; UI hiding alone is not authorization.
- Create migrations, typed Dart models, tests, and concise documentation together with each feature.
- Run formatting, static analysis, focused tests, and milestone integration tests before claiming completion.
- Record assumptions when a non-product implementation detail is missing.

The coding agent MUST ASK before changing scope, roles, core entities, AI provider, target platforms, notification strategy, milestone dates, or any non-negotiable decision.

The coding agent MUST NEVER add IoT/live video, train a model, expose secrets, bypass RLS, invent confirmed disease diagnoses, silently weaken tests, or proceed past a failed milestone gate.

## 4. Product Contract

SVPG is an English-first academic mobile prototype for small-scale plant monitoring. A Farmer registers a plant, manually captures or selects a still image, receives AI-assisted visible-condition guidance, saves the result, manages care tasks, and reviews history and analytics. Guests browse a public encyclopedia. Viewers see explicitly permitted data in read-only mode. Admins manage accounts and encyclopedia content without unrestricted private-image access.

### Goals

- One Flutter codebase for Android and iOS.
- End-to-end image assessment with structured, safe output.
- Traceable plant image and diagnosis history.
- Species-based care tasks and reminders.
- Public plant encyclopedia and Admin content tools.
- All High-priority PRD requirements pass acceptance testing.

### Non-goals for V1

- Physical IoT camera or continuous/live video.
- Automatic image capture.
- Soil, temperature, humidity, light, nutrient, or other sensors.
- Automated irrigation, lighting, fertilization, or actuators.
- Custom model training.
- Confirmed named disease, pest, fungus, or deficiency diagnosis.
- Commercial multi-farm, payments, social community, or separate web app.
- Arabic localization; it is future work.

## 5. Fixed Technical Decisions

- Client: Flutter/Dart with null safety and feature-first modules.
- Backend: Supabase Auth, PostgreSQL, Storage, RLS, and Edge Functions.
- AI: a ready multimodal model called only through `analyze-plant-image` Edge Function.
- Image input: device camera still photo or gallery selection, followed by preview.
- State: explicit loading/empty/success/error states; choose one lightweight state-management package and document it.
- Navigation: declarative routing with route guards.
- Notifications: local scheduled reminders plus stored in-app alerts.
- iOS: validate through a cloud macOS build service.

## 6. Roles and Permissions

| Capability | Guest | Viewer | Farmer | Admin |
|---|---:|---:|---:|---:|
| Browse published encyclopedia | Yes | Yes | Yes | Yes |
| View permitted plant data | No | Yes | Own plants | Only when explicitly granted |
| Create/edit/delete plant | No | No | Own plants | No global override |
| Upload and analyze plant image | No | No | Own plants | No global override |
| Complete care tasks | No | No | Own plants | No global override |
| View analytics | No | Permitted plants | Own plants | Only permitted data |
| Manage users and roles | No | No | No | Yes |
| Manage encyclopedia content | No | No | No | Yes |

Deactivated accounts cannot start a valid session; their data remains preserved. Role changes take effect on the next authorization check.

## 7. Navigation Contract

Unauthenticated flow: `Splash -> Welcome -> Login | Register | Guest Encyclopedia`; `Login -> Forgot Password`; successful authentication routes by role.

Farmer shell bottom navigation: `Home | Plants | Care | Encyclopedia | Profile`.

Viewer reuses permitted Home, Plant Detail, History, Analytics, Encyclopedia, and Profile screens with all mutation controls removed.

Admin shell: `Admin Dashboard | Users | Encyclopedia Management | Profile`.

Primary Farmer flow: `Home -> My Plants -> Plant Detail -> Add Image -> Preview -> Analyze -> Result -> Saved History`.

Every protected deep link checks session, active status, role, and record permission before rendering data.

## 8. Screen Contracts

Each screen must implement loading, empty, error, success, offline, and unauthorized behavior where applicable. Destructive actions require confirmation.

### Entry and identity

- `Splash` (`/splash`): restore session and route to Welcome or authorized shell. No business action.
- `Welcome` (`/welcome`): Login, Register, Continue as Guest. Guest opens published encyclopedia only.
- `Login` (`/login`): email, password; submit, forgot password, register. Generic authentication errors.
- `Register` (`/register`): username, email, password, confirmation; validate uniqueness and strength; creates Farmer profile.
- `Forgot Password` (`/forgot-password`): email; always show a non-enumerating confirmation message.

### Farmer core

- `Home` (`/home`): greeting, plant count, attention summary, upcoming care, recent analysis, quick Add Plant and Analyze actions.
- `My Plants` (`/plants`): owned plant list/grid, search by name/species, empty-state Add Plant.
- `Plant Form` (`/plants/new`, `/plants/:id/edit`): name, species, planting date, location, optional cover image. Validate required fields and ownership.
- `Plant Detail` (`/plants/:id`): overview plus History, Care, Notes, and Analytics entry points; primary Analyze Image action.
- `Image Source` (`/plants/:id/image-source`): Take Photo or Choose from Gallery; still images only.
- `Image Preview` (`/plants/:id/image-preview`): selected image, plant identity, replace, cancel, Analyze. Validate supported type, non-empty file, readability, and maximum 10 MB.
- `Analyzing` (`/analysis/:requestId/progress`): progress, safe cancel/back behavior, no duplicate submission.
- `Diagnosis Result` (`/diagnoses/:id`): analyzed image, health status, signs, severity, confidence note, recommendations, timestamp, disclaimer, retry for recoverable failure.
- `Diagnosis History` (`/plants/:id/diagnoses`): chronological saved results; opens immutable result detail.
- `Image Timeline` (`/plants/:id/images`): chronological images, dates, analysis badges; select exactly two for comparison.
- `Image Comparison` (`/plants/:id/compare?left=&right=`): side-by-side proportional images with dates; no unsupported change claim.
- `Observation Notes` (`/plants/:id/notes`): list/search and add/edit/delete dated notes.
- `Care` (`/care`): upcoming, completed, missed; filter by plant/type/date; mark owned task complete.
- `Care Task Form` (`/plants/:id/care/new`, `/care/:id/edit`): type, title, due date/time, optional recurrence/reminder.
- `Notifications` (`/notifications`): diagnosis and care alerts; opening navigates to the exact record.
- `Analytics` (`/analytics`, `/plants/:id/analytics`): diagnosis events, severity distribution, care compliance, date filters, optional two-plant comparison.
- `Export` (`/plants/:id/export`): select date range and PDF/CSV; output contains plant identity, diagnoses, care activity, and generation date.

### Encyclopedia

- `Encyclopedia` (`/encyclopedia`): public browse/search over published species.
- `Species Detail` (`/encyclopedia/:id`): common/scientific names, conditions, care, common visible problems, and tips. Works without login.

### Profile and settings

- `Profile` (`/profile`): username/email/role, notification preferences, logout, account deactivation entry.
- `Notification Settings` (`/profile/notifications`): category toggles and permission guidance; denied OS permission does not disable in-app alerts.

### Admin

- `Admin Dashboard` (`/admin`): user and encyclopedia summaries with management links.
- `User Management` (`/admin/users`): search users, active state, role.
- `User Detail` (`/admin/users/:id`): change role, deactivate/reactivate with confirmation; no private plant images by default.
- `Encyclopedia Management` (`/admin/species`): drafts/published entries, create/edit/publish/unpublish/delete.
- `Species Form` (`/admin/species/new`, `/admin/species/:id/edit`): required names, care template, conditions, common problems, tips, optional image, publication state.

## 9. Cross-Screen State Rules

- Loading: show progress immediately and disable duplicate primary actions.
- Empty: explain the absence and provide one relevant next action.
- Offline: preserve unsent form/image input; explain which cloud action needs connectivity; allow retry.
- Recoverable error: retain user input and offer retry.
- Unauthorized: do not render protected data; route safely or show access denied.
- Uncertain AI output: visually prominent `Uncertain`, clearer-image guidance, and no diagnosis claim.
- Accessibility: semantic labels, text scaling, adequate contrast, and text/icons in addition to color severity.

## 10. Architecture

Flutter UI calls feature repositories, never Supabase or the AI provider directly from widgets. Repositories call Supabase Auth/database/storage/Edge Function clients. PostgreSQL plus Storage are the durable sources of truth. The AI provider is an external dependency behind the Edge Function.

Suggested repository layout:

```text
lib/
  core/{config,error,routing,theme,widgets}/
  features/
    auth/{data,domain,presentation}/
    plants/{data,domain,presentation}/
    diagnosis/{data,domain,presentation}/
    care/{data,domain,presentation}/
    encyclopedia/{data,domain,presentation}/
    analytics/{data,domain,presentation}/
supabase/{migrations,functions/analyze-plant-image}/
test/
integration_test/
docs/
```

Do not introduce microservices, event buses, custom backend servers, or offline synchronization engines for V1.

## 11. Data Contract

All primary keys use UUID. All timestamps use UTC `timestamptz`. Tables include `created_at`; mutable tables include `updated_at`.

- `profiles`: `user_id`, `username`, `role`, `active_status`, notification preferences.
- `species`: names, care template, growing conditions, common problems, tips, image path, publish status.
- `plants`: owner, species, name, planting date, location, cover image.
- `plant_access`: plant, viewer, permission=`read` for explicit Viewer access.
- `plant_images`: plant, owner, storage path, capture time, upload/analysis status, content type, byte size.
- `diagnoses`: image, plant, owner, health status, signs JSON, severity, confidence note, recommendations JSON, disclaimer, model/provider version, created time.
- `observation_notes`: plant, owner, text, observed time.
- `care_tasks`: plant, owner, type, title, due time, status, completed time, source, reminder time.
- `notifications`: user, optional plant/diagnosis/task, type, message, scheduled/read time.

Required constraints include unique username, valid role/status enums, valid AI enums, non-empty required text, one diagnosis per successful analysis request, and foreign keys with deliberate delete behavior.

Storage buckets: private `plant-images`; public or signed `species-images` according to publication strategy. Owner-scoped path: `{userId}/{plantId}/{imageId}.{ext}`.

## 12. RLS Contract

- Published species are readable by everyone; only Admin can mutate species.
- A Farmer can read/write owned plants and their child records.
- A Viewer can read only plants present in `plant_access`; cannot mutate any child record.
- Admin account-management operations are explicit privileged functions; Admin does not automatically read private plant images.
- Storage access mirrors database ownership/access rules.
- Service-role credentials are limited to trusted server functions and never bundled in Flutter.

Add policy tests proving allowed and denied cases for every role before Milestone 2 closes.

## 13. AI Analysis Contract

### Request

Authenticated `POST /functions/v1/analyze-plant-image`:

```json
{
  "request_id": "uuid",
  "plant_id": "uuid",
  "image_id": "uuid",
  "species_common_name": "string",
  "species_scientific_name": "string|null"
}
```

The function validates identity, ownership, active account, image status, private storage object, size/type, and idempotency before calling the provider.

### Response

```json
{
  "diagnosis_id": "uuid",
  "health_status": "Healthy|Attention Needed|Uncertain",
  "visible_signs": ["wilting"],
  "severity": "None|Low|Medium|High|Uncertain",
  "confidence_note": "Several leaves appear pale and slightly drooped.",
  "recommendations": ["Check soil moisture", "Review recent light exposure"],
  "disclaimer": "AI-assisted visual guidance; not a confirmed diagnosis.",
  "created_at": "ISO-8601 UTC"
}
```

Allowed signs: wilting, discoloration or yellowing, dehydration indicators, pest-like damage, disease-like damage, physical damage, other visible stress. Recommendations are one to five safe checks; no confirmed named disease or chemical prescription.

### Function behavior

1. Authenticate and authorize.
2. Claim `request_id` idempotently.
3. Read image through trusted storage access.
4. Build a versioned prompt including selected species as context, not proof.
5. Apply timeout and one retry only for retryable provider/schema failure.
6. Strictly validate JSON; malformed output never reaches the client as a diagnosis.
7. Save diagnosis and final image status atomically where practical.
8. Return stable success for duplicate completed `request_id`.

If image quality is insufficient, return `Uncertain` with clearer-image guidance. If provider quota/timeout persists, preserve the image and return a retryable safe error without creating a duplicate diagnosis.

## 14. Error Envelope

All trusted backend errors return:

```json
{
  "error": {
    "code": "STABLE_MACHINE_CODE",
    "message": "Safe user-facing message",
    "retryable": true,
    "request_id": "uuid"
  }
}
```

The client maps codes to actionable states and does not display provider responses, stack traces, SQL text, or secrets.

## 15. Definition of Done

A task is done only when implementation, migration/contract changes, permissions, tests, error/empty/loading states, accessibility labels, and concise documentation are complete. A milestone is done only when all High-priority requirements in that milestone pass, format/analyze/tests pass, no critical defect remains, and evidence is recorded.

Required commands:

```text
dart format .
flutter analyze
flutter test
flutter test integration_test
flutter build apk --release
```

At final delivery also validate the iOS project through the selected cloud build environment.

## 16. Milestone Execution Plan

### M1 — Planning and design approved (18–25 Sep)

Deliver: scope baseline, this system design, navigation contract, architecture, schema/API contracts, thesis scope update. Exit: no unresolved blocker to begin foundation.

### M2 — Application foundation ready (25 Sep–2 Oct)

Deliver: Flutter project/repository, theme and shell, Supabase environments/migrations/storage, registration/login/reset, profile and role guards, RLS tests. Exit: Farmer/Admin/Viewer/Guest authorization scenarios pass.

### M3 — Plant tracking ready (2–9 Oct)

Deliver: plant CRUD/species selection, capture/gallery preview/validation, private upload metadata, timeline/comparison/notes. Exit: Farmer creates plant and uploads a timestamped image; Viewer cannot mutate.

### M4 — AI diagnosis ready (9–23 Oct)

Deliver: versioned prompt/schema, secure Edge Function, idempotent workflow, progress/result/history screens, labeled-image evaluation. Exit: validated image produces one structured saved result; invalid/blurry/provider-failure paths are safe.

### M5 — Care and encyclopedia ready (23 Oct–2 Nov)

Deliver: species care templates, tasks/history/reminders, in-app alerts, public encyclopedia, Admin content management. Exit: Guest reads only published content; Farmer completes a task; Admin mutations are protected.

### M6 — Beta ready (2–9 Nov)

Deliver: metrics, filters, comparisons, PDF/CSV export, end-to-end integration. Exit: primary journey passes and report values match stored records.

### M7 — Final submission (9–20 Nov)

Deliver: functional/usability/security/compatibility tests, AI evaluation, fixes, Android release, iOS cloud-build validation, thesis and user guide, demo package. Exit: all High requirements pass and no critical defect remains.

The agent stops after every milestone and returns: changed files, migrations, tests run/results, acceptance evidence, known limitations, and the next milestone preview.

## 17. Acceptance Scenarios

1. Guest searches and opens a published species without signing in.
2. Farmer registers, creates a plant, and receives baseline care data.
3. Farmer selects/captures a valid image, previews it, analyzes it once, and reopens the saved result.
4. Invalid/oversize/unreadable image is rejected before analysis.
5. Blurry/unrelated image returns Uncertain guidance, not a diagnosis.
6. Duplicate analysis submission does not create duplicate diagnosis or provider charge.
7. Viewer can read an explicitly shared plant but sees no mutation controls and backend rejects writes.
8. Farmer cannot access another owner's plant, image, diagnosis, note, task, or storage object.
9. Admin changes account status/role and manages encyclopedia content without automatic private-image access.
10. Care reminder appears once, opens correct task, and completion updates compliance.
11. Analytics filters update all values consistently; exported report matches stored records.
12. Offline/retry paths preserve user input and do not create partial duplicates.

## 18. Open Implementation Choices

The agent may choose, document, and remain consistent on: state-management package, declarative router, immutable model/code-generation package, chart package, PDF/CSV libraries, local-notification package, and cloud iOS build provider. Choices must be actively maintained, compatible with current Flutter/Supabase versions, free for the academic prototype, and no heavier than required.

## 19. Final Instruction to the Coding Agent

Start at M1. Do not implement later milestones early. Before coding, summarize repository state, confirm the authoritative scope and exclusions, identify only true blockers, and propose the smallest milestone plan. After approval, implement with tests, verify the milestone gate, and stop for review.
