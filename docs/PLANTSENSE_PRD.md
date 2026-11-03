# PlantSense - Product Requirements Document (PRD)

PLANTSENSE MONITORING SYSTEM

Product Requirements Document

Mobile Image Based Plant Health and Care Application

Document Information

Value

Document version

1.0

Status

Approved scope baseline for Graduation Project 2

Project period

18 September 2026 to 20 November 2026

Target platforms

Android and iOS

Implementation framework

Flutter

Project Team

Member

Primary Responsibility

Mariam Khalaf Al-Ruwaili

Project coordination and documentation

Ghadi Sultan Alouthah

Flutter development

Alanoud Alkhmees

Backend and database

Raghad Khaled Al-Ruwaili

AI validation and testing

Aryam Saeed Al-Sharari

UI UX and analytics

1 Document Control

This PRD defines the product scope, users, capabilities, functional requirements, quality requirements, data model, acceptance criteria, and release conditions for the PlantSense Monitoring System prototype. It is the product baseline for implementation and for completing the practical chapters of the graduation thesis.

Version

Date

Owner

Change

1.0

15 September 2026

PlantSense Team

Initial PRD aligned with the approved Gantt plan and Graduation Project 1 report

2 Contents

1 Document Control

2 Contents

3 Executive Summary

4 Product Vision and Objectives

5 Users and Stakeholders

6 Product Scope

7 Capability Map and User Journeys

8 Functional Requirements

9 Non Functional Requirements

10 System Architecture and Data Model

11 AI Analysis Contract

12 Error Handling and Product States

13 Testing and Acceptance

14 Release Plan and Gantt Traceability

15 Risks and Mitigations

16 Engineering Baseline and Boundaries

17 Future Work

18 Glossary and Source Baseline

3 Executive Summary

PlantSense is a cross-platform mobile application that helps users register plants, upload plant images, receive AI-assisted visual health assessments, manage care activities, review plant history, and access a public plant encyclopedia. The prototype replaces the live IoT camera described in the theoretical report with user-controlled image capture and upload. Physical cameras, environmental sensors, and automated irrigation remain future work.

The application will be developed with Flutter for Android and iOS. Supabase will provide authentication, PostgreSQL data storage, image storage, row-level access control, and server-side functions. A ready multimodal AI service will analyze images through a secure server-side endpoint so that the model key is never included in the mobile application.

The product is successful when the complete primary journey works end to end: a user creates an account, registers a plant, uploads a usable image, receives a structured assessment, saves the result, reviews the history, manages care tasks, and views analytics. The product must also provide guest encyclopedia access and administrative management functions.

4 Product Vision and Objectives

4.1 Vision

Give home growers, students, and small vertical farming users a simple mobile tool that turns plant images and care records into understandable, timely, and traceable guidance.

4.2 Problem Statement

Small-scale growers often inspect plants only when they remember, maintain inconsistent care notes, and react after visible problems become severe. Existing tools commonly separate image analysis, reminders, growth history, and plant information. PlantSense combines these functions in one academic prototype while keeping the practical scope achievable within the project period.

4.3 Objectives and Success Measures

ID

Objective

Success Measure

OBJ-01

Deliver one Flutter codebase for Android and iOS

Android release build succeeds and an iOS cloud build is validated before 20 November 2026

OBJ-02

Provide a complete image assessment journey

A registered user can upload an image, receive structured results, and save them to history

OBJ-03

Make results understandable

Every successful assessment displays status, visible signs, severity, confidence note, recommendations, and a safety disclaimer

OBJ-04

Support ongoing plant care

Users can view upcoming tasks, mark tasks complete, and review completed or missed activity

OBJ-05

Provide traceable academic evaluation

At least 80 percent agreement with the project labeled validation set for general health categories

OBJ-06

Meet the approved scope

All High-priority requirements pass acceptance testing and no critical defects remain

4.4 Product Assumptions

The first release is an academic prototype for small-scale use and will be validated with approximately two to three plants per test account.

The first release interface and encyclopedia content are in English; Arabic localization is future work.

Internet access is required for authentication, cloud storage, synchronization, and AI analysis.

The selected AI service offers a free tier sufficient for prototype demonstrations and controlled testing.

iOS builds are produced through a cloud macOS build service because the development team does not own a Mac.

Care schedules use approved species templates from the encyclopedia. AI results may recommend reviewing a schedule but do not change it without user confirmation.

5 Users and Stakeholders

Stakeholder

Description

Primary Need

Farmer

Home grower, student, or small vertical farming user

Manage owned plants, images, diagnoses, care tasks, notifications, analytics, and reports

Viewer

Registered read-only user

View permitted plant profiles, histories, and analytics without modifying records

Guest

Unregistered visitor

Browse and search the public Plant Encyclopedia

Admin

System and content administrator

Manage user roles and account status, and create, edit, or remove encyclopedia entries

Project Supervisor

Academic reviewer

Review scope, evidence, testing results, report quality, and final demonstration

6 Product Scope

6.1 In Scope for Version 1

Flutter mobile application for Android and iOS.

Self-registration, login, logout, password reset, role-based authorization, and account deactivation.

Plant profile creation, viewing, editing, deletion, search, and species selection.

Manual image capture or gallery upload with validation, timestamping, storage, timeline, comparison, and observation notes.

AI-assisted detection of general visible plant conditions including healthy appearance, wilting, discoloration or yellowing, dehydration indicators, pest-like damage, disease-like damage, and uncertain results.

Diagnosis history with severity, recommendations, timestamps, and the analyzed image.

Species-based care schedules, upcoming care tasks, completion and missed-task history, and user-created tasks.

In-app alerts and scheduled device notifications.

Public Plant Encyclopedia with search, species profiles, care information, common visible problems, and Admin content management.

Analytics for plant history and care compliance, filtering and comparison, plus PDF and CSV export.

Functional, usability, compatibility, security, and AI validation testing, plus thesis completion and delivery materials.

6.2 Out of Scope for Version 1

A physical IoT camera, continuous video streaming, or automatic frame capture.

Soil moisture, temperature, humidity, light, nutrient, or other physical sensors.

Automated irrigation, lighting, fertilization, or environmental actuators.

Training a custom machine-learning model.

Definitive identification of a specific disease, fungus, deficiency, or pest by name.

Medical-grade or agronomist-certified treatment decisions.

Commercial multi-farm deployment, payment features, social community features, and multilingual localization.

A separate production web application. Administrative functions are included in the mobile prototype.

6.3 Fixed Product Decisions

Area

Decision

Reason

Mobile framework

Flutter and Dart

The team is experienced with Flutter and requires one cross-platform codebase

Backend platform

Supabase free tier

Provides authentication, PostgreSQL, storage, row-level security, and Edge Functions with minimal infrastructure

Image input

Manual camera capture or gallery upload

Matches the practical prototype scope; IoT camera remains future work

AI approach

Ready multimodal model through a secure server function

Avoids custom model training while enabling structured visual analysis

iOS build

Cloud macOS build

Allows iOS compilation without a local Mac

7 Capability Map and User Journeys

7.1 Capability Map

Module ID

Responsibility

Depends On

identity-access

Accounts, sessions, roles, and data access

None

plant-management

Plant profiles, species selection, and ownership

identity-access

image-tracking

Image upload, storage, timeline, comparison, and notes

plant-management

ai-diagnosis

Secure model call, structured results, history, and evaluation

image-tracking

care-management

Species schedules, task status, history, and reminders

plant-management

encyclopedia

Public knowledge base and Admin content management

identity-access

analytics-reporting

Health and care metrics, filters, comparisons, and exports

ai-diagnosis and care-management

quality-delivery

Testing, builds, thesis evidence, and final package

all product capabilities

Build order: identity-access, plant-management, image-tracking, ai-diagnosis, care-management and encyclopedia, analytics-reporting, then quality-delivery.

7.2 Primary User Journey

1.  The user creates an account or signs in.

2.  The user registers a plant and selects its species.

3.  The system creates a baseline care schedule from the species profile.

4.  The user captures or selects a plant image and confirms the selected plant.

5.  The app validates and uploads the image, then requests AI analysis through the secure backend.

6.  The app presents health status, visible signs, severity, recommendations, and an uncertainty disclaimer.

7.  The result is saved to the plant history and can generate an in-app alert when attention is required.

8.  The user reviews care tasks, marks completed work, and views analytics or exports a report.

7.3 Guest and Admin Journeys

A Guest can open the app, browse or search the public Plant Encyclopedia, and view species care information without registering. An Admin signs in, manages encyclopedia entries, changes user roles, and deactivates or reactivates accounts while preserving their data.

8 Functional Requirements

Priority meanings: High requirements are required for the final demonstration; Medium requirements are expected unless a documented project risk prevents delivery; Low requirements are implemented only after all High requirements pass testing.

8.1 Identity and Access

ID

Requirement

Priority

Acceptance Criteria

FR-AUTH-01

A new user can register with a unique username, email address, and password.

High

Valid details create one Farmer account; duplicate email or username receives a clear error.

FR-AUTH-02

A registered user can sign in and sign out securely.

High

Correct credentials open the authorized home screen; logout removes the active session.

FR-AUTH-03

A user can request a password-reset email.

Medium

A valid account receives a secure reset link without exposing whether other emails exist.

FR-AUTH-04

The system enforces Admin, Farmer, and Viewer permissions.

High

Unauthorized create, edit, delete, or Admin actions are rejected by both the interface and backend rules.

FR-AUTH-05

A Guest can access the public encyclopedia without signing in.

High

Browse, search, and species detail screens open without an authenticated session.

FR-AUTH-06

An Admin can change roles and deactivate or reactivate accounts.

High

Changes take effect on the next authorization check; deactivation preserves existing records.

8.2 Plant Management

ID

Requirement

Priority

Acceptance Criteria

FR-PLANT-01

A Farmer can register a plant with name, species, planting date, location, and optional cover photo.

High

Required fields are validated and the created plant is linked to the current user.

FR-PLANT-02

A Farmer can view and search owned plants.

High

The list loads the user's plants and supports search by plant name or species.

FR-PLANT-03

A Farmer can view, edit, and delete an owned plant.

High

Updates persist; deletion requires confirmation and does not affect another user's data.

FR-PLANT-04

Selecting a species connects the plant to encyclopedia care data.

High

The plant stores a species reference and displays the relevant baseline care information.

FR-PLANT-05

A Viewer can open permitted plant profiles in read-only mode.

Medium

No edit, upload, task-completion, or delete controls are available to the Viewer.

8.3 Image and Observation Tracking

ID

Requirement

Priority

Acceptance Criteria

FR-IMG-01

A Farmer can capture a photo or select one from the device gallery.

High

Both input methods return a preview before upload on supported Android and iOS devices.

FR-IMG-02

The app validates image type, size, and readability before analysis.

High

JPG, PNG, and supported mobile image formats up to 10 MB are accepted; invalid or empty files are rejected.

FR-IMG-03

Every uploaded image is linked to a plant and timestamped.

High

The database record includes owner, plant, storage path, capture or upload time, and analysis status.

FR-IMG-04

A user can browse a chronological image timeline for a plant.

High

Images appear newest-first or oldest-first without mixing records from other plants.

FR-IMG-05

A user can compare two selected images side by side.

Medium

The comparison shows both dates and maintains usable image proportions.

FR-IMG-06

A Farmer can add, edit, search, and delete dated observation notes.

Medium

Notes remain linked to the selected plant and date and are searchable by keyword.

8.4 AI Image Analysis

ID

Requirement

Priority

Acceptance Criteria

FR-AI-01

A Farmer can request analysis for a validated plant image.

High

The request includes plant species and the stored image reference and produces one traceable analysis record.

FR-AI-02

The AI response uses the approved structured response contract.

High

The backend accepts only a valid schema containing status, signs, severity, confidence note, recommendations, and disclaimer.

FR-AI-03

The system detects general visible health signs rather than claiming a definitive diagnosis.

High

Outputs use approved categories and do not name a specific disease or pest as confirmed.

FR-AI-04

The app displays a clear result screen.

High

The screen shows the analyzed image, health status, visible signs, severity, explanation, recommendations, and timestamp.

FR-AI-05

Analysis results are saved in plant history.

High

Reopening the plant displays the original image and stored result without repeating the model request.

FR-AI-06

Low-quality, unrelated, or uncertain images are handled safely.

High

The result becomes Uncertain and asks for a clearer image instead of inventing a diagnosis.

FR-AI-07

The AI service key remains server-side.

High

No production key is present in the Flutter source, app bundle, logs, or client network configuration.

FR-AI-08

A failed model request can be retried without duplicate history records.

Medium

The user receives a recoverable error and one successful retry creates exactly one final diagnosis.

8.5 Care Management and Notifications

ID

Requirement

Priority

Acceptance Criteria

FR-CARE-01

A species-based baseline care schedule is created for a new plant.

High

The schedule includes watering, lighting, fertilization, and humidity guidance when available.

FR-CARE-02

A Farmer can view upcoming and overdue care tasks.

High

Tasks are grouped or sorted by due date and show type, plant, status, and due time.

FR-CARE-03

A Farmer can mark a care task complete.

High

Completion time and user are saved and the care history updates immediately.

FR-CARE-04

The system records completed and missed tasks.

High

Past tasks remain available by plant and date with an unambiguous status.

FR-CARE-05

A Farmer can create a custom care task.

Low

A valid title, plant, due date, and reminder setting create one editable task.

FR-NOTIF-01

The app shows in-app alerts for AI attention results and due or missed tasks.

High

Opening the notification leads to the correct plant, diagnosis, or care task.

FR-NOTIF-02

The device receives scheduled reminders when notifications are permitted.

Medium

A scheduled care task produces one notification at the configured reminder time.

FR-NOTIF-03

A user can enable or disable notification categories.

Low

Disabled categories do not schedule new notifications; essential in-app status remains visible.

8.6 Plant Encyclopedia

ID

Requirement

Priority

Acceptance Criteria

FR-ENC-01

Guests and authenticated users can browse and search species.

High

Search matches common or scientific names and returns published entries only.

FR-ENC-02

A species profile shows care requirements, growing conditions, common visible problems, and tips.

High

All required sections are readable without login and missing optional data is handled cleanly.

FR-ENC-03

An Admin can create, edit, publish, unpublish, and delete encyclopedia entries.

High

Authorized changes persist, are validated, and are not available to non-Admin users.

FR-ENC-04

Plant registration can select a published encyclopedia species.

High

The selected entry supplies the initial care template without duplicating species data.

8.7 Analytics and Reports

ID

Requirement

Priority

Acceptance Criteria

FR-AN-01

The dashboard summarizes plant age, diagnosis events, severity distribution, and care compliance.

High

Metrics match the underlying records for the selected plant and period.

FR-AN-02

Users can filter analytics by plant, species, and date range.

Medium

Changing a filter updates every visible metric and chart consistently.

FR-AN-03

Users can compare health and care trends for two plants.

Low

Both plants use the same time scale and labels remain distinguishable.

FR-AN-04

A user can export a plant report as PDF or CSV.

Low

The exported file contains plant identity, selected period, diagnoses, care activity, and generation date.

FR-AN-05

A Viewer can access permitted analytics without editing source records.

Medium

The Viewer sees the same approved metrics but no mutation actions.

9 Non Functional Requirements

ID

Requirement

NFR-01 Performance

Primary screens load within 3 seconds on a normal connection; non-AI API calls complete within 2 seconds for the prototype dataset.

NFR-02 AI Responsiveness

An AI request shows progress immediately and normally returns within 20 seconds; longer requests can be canceled or retried.

NFR-03 Security

All network traffic uses HTTPS; authentication is provider-managed; authorization is enforced with backend policies; secrets remain server-side.

NFR-04 Privacy

Plant images and private records are accessible only to the owner, explicitly permitted Viewers, and authorized Admin operations.

NFR-05 Reliability

Retryable operations are idempotent, user input is preserved after recoverable errors, and failures never create partial duplicate records.

NFR-06 Compatibility

The application supports Android 8.0 or later and iOS 13 or later with responsive layouts from 320 px phone width.

NFR-07 Usability

A first-time user can register a plant and complete one image analysis without a tutorial; primary actions are reachable with one hand.

NFR-08 Accessibility

Interactive controls have semantic labels, adequate contrast, readable text scaling, and non-color indicators for health severity.

NFR-09 Scalability

The prototype design supports at least 100 concurrent users without schema redesign, subject to free-tier service limits.

NFR-10 Maintainability

Features are separated by module, models use typed validation, and automated checks run before a release build.

10 System Architecture and Data Model

10.1 Architecture

1.  Flutter mobile client presents the interface, validates user input, captures images, and displays synchronized data.

2.  Supabase Auth manages registration, sessions, password reset, and user identity.

3.  Supabase PostgreSQL stores profiles, plants, species, image metadata, diagnoses, notes, care tasks, and notification preferences.

4.  Supabase Storage stores plant and encyclopedia images in access-controlled buckets.

5.  A Supabase Edge Function validates the analysis request, obtains the image securely, calls the selected multimodal AI service, validates the structured response, and stores the result.

6.  Device notification scheduling handles predictable care reminders; in-app alerts are driven by stored diagnosis and care status.

10.2 Core Data Entities

Entity

Key Fields

Purpose

UserProfile

user_id, username, role, active_status, notification_preferences

Extends the authentication identity

Species

species_id, names, care_template, conditions, common_problems, tips, publish_status

Public encyclopedia source

Plant

plant_id, owner_id, species_id, name, planting_date, location, cover_image

Primary user-owned record

PlantImage

image_id, plant_id, owner_id, storage_path, captured_at, upload_status

Timestamped visual record

Diagnosis

diagnosis_id, image_id, status, signs, severity, confidence_note, recommendations, created_at

Stored AI assessment

ObservationNote

note_id, plant_id, owner_id, note_text, observed_at

Searchable user observation

CareTask

task_id, plant_id, type, title, due_at, status, completed_at, source

Scheduled or custom care work

Notification

notification_id, user_id, plant_id, type, message, scheduled_at, read_at

In-app or device alert state

10.3 Data Access Rules

Farmers can create and modify only their owned plants and related private records.

Viewers receive read-only access only to records explicitly allowed by the product configuration.

Guests can read published Species records only.

Admins can manage roles and Species content but do not receive unrestricted access to private plant images by default.

Deleting a user-facing record follows defined database relationships and must not expose orphaned storage objects.

11 AI Analysis Contract

11.1 Approved Output Categories

Field

Allowed Values or Rule

health_status

Healthy, Attention Needed, or Uncertain

visible_signs

Zero or more of wilting, discoloration or yellowing, dehydration indicators, pest-like damage, disease-like damage, physical damage, or other visible stress

severity

None, Low, Medium, High, or Uncertain

confidence_note

Short plain-language explanation of visible evidence and uncertainty; not a numeric claim unless the provider supplies a calibrated score

recommendations

One to five safe observation or care-check suggestions; no prohibited chemicals or definitive treatment claim

disclaimer

States that the output is AI-assisted visual guidance and not a confirmed agronomic diagnosis

11.2 Example Structured Response

{  "health_status": "Attention Needed",  "visible_signs": ["discoloration or yellowing", "wilting"],  "severity": "Medium",  "confidence_note": "Several leaves appear pale and slightly drooped.",  "recommendations": ["Check soil moisture", "Review recent light exposure"],  "disclaimer": "AI-assisted visual guidance; not a confirmed diagnosis."}

11.3 AI Validation Rules

The server rejects responses that do not match the required schema and may retry once with the same image request.

The model must be told the selected species but must not claim that the image proves the species identity.

When the image is blurry, dark, unrelated, or insufficient, the approved output is Uncertain with a request for a better image.

Evaluation uses a versioned labeled image set and reports agreement by category, common errors, and limitations in the thesis.

The application never presents AI output as a replacement for an agricultural specialist.

12 Error Handling and Product States

Condition

Required Product Behavior

No network

Preserve the selected image and form data; explain that upload and analysis require connectivity; allow retry.

Invalid credentials

Show a generic authentication error without exposing account existence or backend details.

Unauthorized action

Hide unavailable controls and reject the request at the backend with a safe message.

Invalid image

Explain the supported input and ask the user to choose or capture another image.

Upload failure

Keep the local preview, mark the operation failed, and retry without creating duplicate records.

AI timeout or quota limit

Show a recoverable service message, retain the uploaded image, and allow retry later.

Uncertain analysis

Display Uncertain prominently and provide image-quality guidance rather than a diagnosis.

Notification permission denied

Keep in-app alerts active and show where device reminders can be enabled later.

Empty state

Provide a clear next action such as Add Plant, Upload First Image, or Create Care Task.

13 Testing and Acceptance

Test Level

Coverage

Exit Condition

Unit tests

Validation, typed models, care calculations, permissions helpers, and AI response parsing

All focused tests pass

Widget tests

Authentication, plant forms, image preview, diagnosis result, care list, and empty/error states

Critical screens render and respond correctly

Integration tests

Register, add plant, upload image, analyze, save history, complete care task, view analytics

Primary journey passes without manual database repair

Backend policy tests

Owner isolation, Viewer read-only rules, Guest species access, and Admin actions

Unauthorized reads and writes are rejected

AI validation

Labeled images representing healthy, wilting, discoloration, dehydration indicators, damage, and uncertain inputs

At least 80 percent category agreement, with limitations documented

Compatibility

Representative Android device or emulator and an iOS cloud build with available device validation

No critical platform-specific failure

Usability

First-time user completes registration, plant creation, and analysis

Flow completes without assistance and feedback is understandable

13.1 Final Acceptance Criteria

Every High-priority functional requirement has a passing test or recorded demonstration evidence.

No open defect blocks login, plant registration, image upload, AI result display, history, care tasks, or Guest encyclopedia access.

Android release build succeeds and the iOS project succeeds in the selected cloud build environment.

The AI evaluation dataset, labels, results, limitations, and representative screenshots are included in the thesis evidence.

The final report, source package, user guide, presentation, and demonstration data are complete and internally consistent.

14 Release Plan and Gantt Traceability

Phase

Period

PRD Coverage

Exit Milestone

Phase 1

18 to 25 September

Planning, UX, architecture, thesis scope update

Milestone 1 Planning and design approved

Phase 2

25 September to 2 October

Flutter foundation, backend, authentication, roles

Milestone 2 Application foundation ready

Phase 3

2 to 9 October

Plant profiles, image tracking, notes, module documentation

Milestone 3 Plant tracking module ready

Phase 4

9 to 23 October

AI contract, secure endpoint, Flutter integration, evaluation

Milestone 4 AI diagnosis module ready

Phase 5

23 October to 2 November

Care schedules, notifications, encyclopedia, Admin content

Milestone 5 Care and encyclopedia modules ready

Phase 6

2 to 9 November

Analytics, filters, exports, end-to-end integration

Milestone 6 Beta release ready

Phase 7

9 to 20 November

Testing, fixes, builds, thesis completion, final delivery

Milestone 7 Final project submission

15 Risks and Mitigations

Risk

Impact

Mitigation

AI output is inconsistent or overconfident

High

Use a strict schema, limited categories, uncertainty rules, labeled validation images, and visible disclaimers.

Free-tier AI or backend quota is exhausted

High

Limit image size, cache saved results, prevent duplicate requests, monitor usage, and prepare demonstration records.

No local Mac for iOS

Medium

Use a cloud macOS build service early enough to resolve signing and plugin issues before the final week.

Nine-week schedule is compressed

High

Protect High-priority flows, enforce milestone gates, and defer Low-priority comparison or export features if necessary.

Image uploads expose private data

High

Use private storage, owner-scoped paths, signed access, backend policies, and no public diagnostic images.

Notification behavior differs by platform

Medium

Use a supported Flutter notification package and test permissions and scheduling on both platforms.

Thesis and implementation diverge

Medium

Update the relevant thesis sections during every phase and maintain traceability to requirement IDs.

16 Engineering Baseline and Boundaries

16.1 Project Structure

Location

Responsibility

lib/core

Shared configuration, errors, networking, theme, routing, and common widgets

lib/features/auth

Registration, login, sessions, profiles, and authorization

lib/features/plants

Plant profiles, species selection, images, timeline, and notes

lib/features/diagnosis

Analysis request, typed response, results, history, and AI error states

lib/features/care

Care schedules, task history, and notifications

lib/features/encyclopedia

Public browsing, search, species details, and Admin management

lib/features/analytics

Metrics, filters, charts, comparisons, and export

test and integration_test

Unit, widget, and end-to-end automated tests

supabase/functions

Server-side AI proxy and trusted backend operations

docs

PRD, architecture decisions, test evidence, and thesis-support material

16.2 Required Commands

Purpose

Command

Install dependencies

flutter pub get

Format

dart format .

Static analysis

flutter analyze

Run tests

flutter test

Run integration tests

flutter test integration_test

Android release

flutter build apk --release

Serve backend function locally

supabase functions serve analyze-plant-image

16.3 Code Style Example

final diagnosis = DiagnosisResult.fromJson(responseJson);if (diagnosis.healthStatus == HealthStatus.uncertain) {  return const AnalysisOutcome.requestClearerImage();}return AnalysisOutcome.success(diagnosis);

Use feature-based modules, immutable typed models, explicit result states, descriptive names, null safety, and the standard Dart formatter. UI widgets must not contain service keys or direct model-provider logic.

16.4 Delivery Boundaries

Boundary

Rule

Always

Validate inputs and AI responses; enforce backend authorization; run formatting, analysis, and tests; update thesis evidence when a feature is completed.

Ask first

Change the approved scope, database entities, user roles, AI provider, notification strategy, supported platforms, or milestone dates.

Never

Commit secrets; call the AI provider directly from the mobile client; present uncertain output as confirmed; bypass backend access rules; remove failing tests to pass a build.

17 Future Work

Physical IoT camera integration for scheduled or continuous image capture.

Environmental sensors for soil moisture, temperature, humidity, lighting, and nutrients.

Specialized machine-learning models for named diseases, fungal infections, deficiencies, and pests.

Automated irrigation and environmental control actuators.

Arabic localization and multilingual encyclopedia content.

Community contributions with moderation and expert review.

Large-scale multi-farm dashboards and commercial deployment support.

18 Glossary and Source Baseline

Term

Meaning

AI

Artificial Intelligence

API

Application Programming Interface

CRUD

Create, Read, Update, and Delete

IoT

Internet of Things

MVP

Minimum Viable Product

PSMS

PlantSense Monitoring System

PRD

Product Requirements Document

RLS

Row-Level Security

18.1 Source Baseline

PLANTSENSE MONITORING SYSTEM.docx, Graduation Project 1 theoretical report.

PlantSense Implementation Plan.gan, approved sequential implementation schedule from 18 September to 20 November 2026.

Moubser Implementation Plan.pdf and PNG, visual references for Gantt structure only.

This PRD supersedes theoretical statements that require a physical live camera in the current prototype. For Version 1, manual image upload is the approved input method, general visible-condition assessment is the approved AI function, and physical IoT hardware remains future work.