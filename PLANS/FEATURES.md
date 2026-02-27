# FEATURES.md — Pebee Health App Specification

> **Last updated:** Session 8
> Update this document at the end of every session when features change.

---

## 1. Splash Screen

**Native splash** (via `flutter_native_splash`):
- Cream background (`#F2EDE7`) with full Pebee Health logo (purple text + golden bars)
- Bridges to Flutter via `FlutterNativeSplash.preserve()` / `.remove()` in `main.dart`
- Android 12+ uses bars-only icon (`app_icon_foreground.png`) due to 240dp circle constraint; full logo on pre-12 and iOS

**Flutter splash route** (`/`):
- Initial route — same visual as native splash
- Router redirect keeps user on splash while auth is loading
- Once auth resolves → `/login` (unauthenticated) or `/home/dashboard` (authenticated)
- Prevents login screen flash for returning users

---

## 2. Localisation

**Languages:** Slovak (SK), English (EN), Ukrainian (UA), German (DE)

**Language switcher** — compact `PopupMenuButton` (flag + ISO code chip → dropdown with full language names + checkmark on active). Present on: login, signup, forgot-password, reset-password screens.

**Persistence:** EasyLocalization stores selected locale in `SharedPreferences`. `startLocale: Locale('sk')` only applies on first launch; subsequent launches use the saved preference.

**Signup metadata:** User's active locale is sent as `locale` in `raw_user_meta_data` on signup → synced to `public.profiles` via Postgres trigger → available for localised emails via Edge Functions.

**Translation files:** `apps/mobile/assets/translations/{en,sk,uk,de}.json`

---

## 3. Authentication Flow

### 3.1 Login

**Screen:** Email + password fields, "Sign in" button, "Forgot password?" link, "Create account" link.

**Validation:**
- Email: required, must match email regex
- Password: required (no length check on login — only on signup/reset)

**Error handling:**
- Invalid credentials → error banner with `auth.login.error`
- Unverified email → `EmailNotConfirmedException` → auto-redirect to email verification screen with email pre-filled

### 3.2 Signup

**Screen:** First name, last name, email, password, confirm password, two consent checkboxes (T&C + Privacy Policy), "Create account" button.

**Button state:** Disabled (greyed out) until all 5 text fields are non-empty AND both checkboxes checked. Real-time updates via controller listeners.

**Validation (on tap):**
- Email: required, valid format
- Password: minimum 8 characters
- Confirm password: must match password

**Consent checkboxes:**
- Terms & Conditions — links to `pebeehealth.com/terms` (placeholder)
- Privacy Policy — links to `pebeehealth.com/privacy` (placeholder)
- Both required to enable the submit button

**On success:** Navigates to email verification screen.

### 3.3 Email Verification

**Screen:** 8-digit OTP input (Supabase sends 8-digit codes), "Verify" button, "Resend code" link with 60s cooldown timer.

**Security:**
- 5-attempt lock — after 5 failed attempts, input is disabled
- 60s resend cooldown — rate-limit detection starts timer on `ResendRateLimitedException` (HTTP 429)

**On success:** Supabase auto-signs in → router redirects to `/home/dashboard`.

### 3.4 Password Requirements

| Context | Min length | Confirmation | Additional |
|---------|-----------|-------------|------------|
| Signup | 8 chars | Must match confirm field | — |
| Reset password | 8 chars | Must match confirm field | — |
| Login | No check | — | Validated server-side |

### 3.5 Forgot Password

**Screen:** Email input → "Send reset link" button → success view with email icon + "Check your email" message.

**Flow:** Calls `AuthRepository.resetPasswordForEmail()` → Supabase sends magic link email with `redirectTo: com.pebeehealth.mobile://reset-password`.

### 3.6 Reset Password (via deep link)

**Deep link flow:**
1. User taps magic link in email → opens Supabase verify URL in browser
2. Browser exchanges PKCE token, redirects to `com.pebeehealth.mobile://reset-password?code=AUTH_CODE`
3. OS opens app via custom URL scheme
4. `deepLinkHandlerProvider` (via `app_links`) intercepts the URI
5. `AuthRepository.handleDeepLink()` calls `getSessionFromUrl(uri)` → PKCE code exchanged for session
6. `AuthChangeEvent.passwordRecovery` fires on `onAuthStateChange`
7. `passwordRecoveryProvider` emits `true` → router redirects to `/reset-password`
8. User enters new password + confirmation
9. `AuthRepository.updatePassword()` called → success view → sign out → login

**Deep link config:**
- iOS: `CFBundleURLTypes` in `Info.plist` with scheme `com.pebeehealth.mobile`
- Android: intent-filter in `AndroidManifest.xml` with same scheme
- Supabase: `com.pebeehealth.mobile://reset-password` in Redirect URLs
- `detectSessionInUri: false` in `FlutterAuthClientOptions` — prevents race condition where SDK processes deep link before Riverpod providers are listening
- `deepLinkHandlerProvider` handles both cold-start (`getInitialLink()`) and warm-start (`uriLinkStream`) deep links

**Security (handled by Supabase):** Link expires after 1 hour (default), single-use token, rate limiting on reset requests.

---

## 4. Consent System

### 4.1 Terms & Conditions + Privacy Policy

Checkboxes on signup screen. Consent records saved via `POST /consents` on first login (home screen). Derived providers (`hasTermsConsentProvider`, `hasPrivacyConsentProvider`) prevent duplicate saves.

### 4.2 ATT (App Tracking Transparency)

**iOS only.** In-app dialog explains tracking purpose → triggers native iOS ATT popup. Consent result saved via `POST /consents` with `consentType: 'att'`. `hasAttConsentProvider` prevents popup on subsequent visits.

**Trigger:** `ref.listen` in `DashboardScreen.build()` — fires when consent data loads after login.

### 4.3 Consent Types

| Type | Required | Platform | Notes |
|------|---------|----------|-------|
| `terms` | Yes | Both | Cannot use app without accepting |
| `privacy` | Yes | Both | Cannot use app without accepting |
| `att` | No | iOS | Declining just disables analytics |

---

## 5. Navigation & Routing

**Router:** GoRouter with auth guard via `refreshListenable`.

### 5.1 Routes

| Route | Screen | Auth required |
|-------|--------|---------------|
| `/` | Splash | No (loading state) |
| `/login` | Login | No |
| `/signup` | Signup | No |
| `/email-verification` | OTP Verification | No |
| `/forgot-password` | Forgot Password | No |
| `/reset-password` | Reset Password | No (recovery session) |
| `/home/dashboard` | Dashboard (tab 1) | Yes |
| `/home/therapist` | Coming Soon (tab 2) | Yes |
| `/home/mri-reader` | Coming Soon (tab 3) | Yes |
| `/home/wellbeing` | Coming Soon (tab 4) | Yes |

### 5.2 Bottom Navigation (Shell)

**Implementation:** `StatefulShellRoute.indexedStack` — GoRouter's native shell mechanism.

**`MainShell`** wraps all `/home/*` routes with shared Scaffold:
- AppBar: centered "Pebee Health" title + logout `IconButton`
- Body: `StatefulNavigationShell` (active tab content from GoRouter)
- `NavigationBar` (Material 3) with 4 destinations:

| Tab | Label key | Icon (outline/filled) | Notes |
|-----|-----------|----------------------|-------|
| Home | `dashboard.tabs.home` | `home_outlined` / `home` | Default tab |
| Therapist | `dashboard.tabs.therapist` | `people_outlined` / `people` | Placeholder |
| MRI Reader | `dashboard.tabs.mriReader` | `document_scanner_outlined` / `document_scanner` | Placeholder |
| Wellbeing | `dashboard.tabs.wellbeing` | `spa_outlined` / `spa` | `Badge` with "Coming soon" |

**Tab state:** `indexedStack` preserves widget state across tab switches (no rebuild).

### 5.3 Redirect Logic

- Loading → stay on splash
- Password recovery event → `/reset-password`
- Authenticated on auth route → `/home/dashboard`
- Unauthenticated on protected route (`/home/*`) → `/login`

---

## 6. App Branding

- **App name:** "Pebee Health" (both platforms)
- **App icon:** Golden bars on purple `#6B68E6` background (adaptive icon on Android)
- **Theme colours:** Cream background `#F2EDE7`, primary `#6B68E6`, accent `#F4AF4B`, error `#D32F2F`
- **AppBar:** `centerTitle: true` for visual parity across iOS and Android

---

## 7. Architecture — Mobile

**Pattern:** Feature-first folder structure + Repository pattern + Riverpod state management.

```
lib/
├── core/
│   ├── network/          api_client.dart (platform-aware base URL)
│   ├── router/           app_router.dart (GoRouter + auth guard + StatefulShellRoute)
│   ├── theme/            app_colors.dart, app_theme.dart
│   └── widgets/          language_switcher.dart
├── features/
│   ├── auth/
│   │   ├── data/         auth_repository.dart (Supabase boundary)
│   │   ├── providers/    auth_provider.dart (AuthNotifier, authStateProvider, passwordRecoveryProvider)
│   │   └── presentation/ screens/ (login, signup, verification, forgot-password, reset-password)
│   │                     widgets/ (password_field.dart)
│   ├── consent/
│   │   ├── data/         consent_repository.dart
│   │   ├── models/       user_consent.dart
│   │   ├── providers/    consent_provider.dart (consentsProvider, hasAtt/Terms/Privacy)
│   │   └── services/     tracking_consent_service.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       ├── screens/  dashboard_screen.dart (consent check + mocked dashboard UI)
│   │       └── widgets/  greeting_header, stat_card, weekly_goal_card,
│   │                     todays_exercise_card, training_plan_section
│   ├── placeholder/
│   │   └── presentation/
│   │       └── screens/  coming_soon_screen.dart (reusable placeholder)
│   ├── shell/
│   │   └── presentation/
│   │       └── screens/  main_shell.dart (bottom nav + AppBar scaffold)
│   └── splash/           splash_screen.dart
```

**Key principle:** Only `AuthRepository` imports `supabase_flutter` — rest of app uses providers.

---

## 8. Dashboard (Home Tab)

**Screen:** `DashboardScreen` — `ConsumerStatefulWidget` with `SingleChildScrollView` body. No Scaffold (provided by `MainShell`).

### 8.1 Widgets (top to bottom)

| Widget | Description | Data source |
|--------|-------------|-------------|
| `GreetingHeader` | "Hello, {firstName}!" + `CircleAvatar` with first letter (or `?` fallback) | `user?.userMetadata?['first_name']` from auth |
| `StatCard` (×2 in Row) | "Overall progress: 85%" + "Completed exercises: 23" | Mocked (hardcoded) |
| `WeeklyGoalCard` | "Weekly goal" + `LinearProgressIndicator` (3/5) | Mocked |
| `TodaysExerciseCard` | Grey placeholder image + exercise title/level/duration + teal "Start exercise" button | Mocked via translation keys |
| `TrainingPlanSection` | "Training plan" header + "More" link + horizontal scrollable row of 7 day indicators | Mocked (days 16-22 with statuses) |

### 8.2 Day Indicators (Training Plan)

Each `_DayIndicator` shows: day number + status icon below:
- **Completed** (green `✓`): `Colors.green`, `Icons.check_circle`
- **Missed** (red `✗`): `Colors.red`, `Icons.cancel`
- **Skipped** (grey `—`): `Colors.grey`, `Icons.remove_circle`
- **Pending** (outline): `Colors.grey.shade300`, `Icons.circle_outlined`

### 8.3 Consent Logic (migrated from old HomeScreen)

Same `ref.listen(consentsProvider)` + `_consentCheckDone` pattern:
1. On first load after login, checks if T&C + Privacy consents exist
2. If missing, auto-saves via `POST /consents`
3. Then checks ATT consent (iOS only) — shows in-app dialog + native ATT popup
4. `hasTermsConsentProvider`, `hasPrivacyConsentProvider`, `hasAttConsentProvider` prevent re-triggering

---

## 9. Placeholder Tabs

`ComingSoonScreen` — reusable `StatelessWidget` with `title` parameter. Displays centered `Icons.construction_rounded` icon + "Coming soon" text. No Scaffold (shell provides it).

Used by: Therapist tab, MRI Reader tab, Wellbeing tab.

---

## 10. Backend (NestJS)

### 10.1 Module Structure

| Module | Purpose |
|--------|---------|
| `AuthModule` | JWT strategy (JWKS/ES256), guard, `@CurrentUser()` decorator |
| `ConsentsModule` | CRUD for user consent records |
| `SupabaseModule` | Server-side Supabase client wrapper |
| `HealthController` | `GET /health` endpoint |

### 10.2 API Endpoints

| Method | Path | Auth | Body | Response |
|--------|------|------|------|----------|
| `GET` | `/health` | No | — | `{ status: 'ok' }` |
| `GET` | `/auth/me` | Yes | — | `{ userId, email }` |
| `GET` | `/consents` | Yes | — | `UserConsent[]` |
| `POST` | `/consents` | Yes | `{ consentType, granted, platform }` | `UserConsent` |

**Validation:** Zod schemas via `ZodValidationPipe`. Consent types: `att`, `terms`, `privacy`. Platform: `ios`, `android`, `web`.

### 10.3 JWT Authentication

- Fetches signing keys from Supabase JWKS endpoint (`/auth/v1/.well-known/jwks.json`)
- ES256 algorithm (Supabase migrated from HS256)
- `jwks-rsa` with caching and rate limiting (5 requests/min)
- Extracts `{ userId, email }` from JWT payload → available via `@CurrentUser()` decorator

### 10.4 Environment Variables

| Variable | Required | Description |
|----------|---------|-------------|
| `SUPABASE_URL` | Yes | Supabase project URL |
| `SUPABASE_SECRET_KEY` | Yes | Service role key (server-side only) |
| `PORT` | No | Server port (default: 3001) |

---

## 11. Database (Supabase Postgres)

### 11.1 Tables

**`auth.users`** — Managed by Supabase Auth. Contains `raw_user_meta_data` with `first_name`, `last_name`, `locale`.

**`public.profiles`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | References `auth.users.id` |
| `email` | text | |
| `first_name` | text | From user metadata |
| `last_name` | text | From user metadata |
| `locale` | text | Default: `'en'` |
| `created_at` | timestamptz | |

- Populated by Postgres trigger `handle_new_user()` on `auth.users` INSERT
- RLS: users read/update own row; service role full access

**`public.user_consents`**

| Column | Type | Notes |
|--------|------|-------|
| `id` | UUID (PK) | Auto-generated |
| `user_id` | UUID (FK) | References `auth.users.id` |
| `consent_type` | text | `att`, `terms`, `privacy` |
| `granted` | boolean | |
| `platform` | text | `ios`, `android`, `web` |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

- `UNIQUE(user_id, consent_type)` constraint — enables upsert on conflict

---

## 12. Error Handling

### Mobile (Flutter)

| Error | Where | User sees |
|-------|-------|-----------|
| Invalid credentials | Login | Error banner: `auth.login.error` |
| Email not confirmed | Login | Auto-redirect to verification screen |
| Email already registered | Signup | Error banner: `auth.signup.error` |
| OTP invalid/expired | Verification | Error banner: `auth.verification.error` |
| Resend rate limited (429) | Verification | Snackbar: `auth.verification.resendRateLimited` + cooldown starts |
| Reset email failed | Forgot password | Error banner: `auth.forgotPassword.error` |
| Password update failed | Reset password | Error banner: `auth.resetPassword.error` |

### Backend (NestJS)

- Zod validation failures → 400 Bad Request with validation details
- Missing/invalid JWT → 401 Unauthorized
- Supabase errors → logged via `Logger`, returned as 500

### Typed Domain Exceptions

| Exception | Trigger | UI behaviour |
|-----------|---------|-------------|
| `EmailNotConfirmedException` | Login with unverified email | Redirect to verification |
| `ResendRateLimitedException` | OTP resend returns 429 | Start 60s cooldown timer |

---

## 13. Test Coverage

### Flutter — 69 tests across 11 files

| File | Tests | Covers |
|------|-------|--------|
| `password_field_test.dart` | 6 | Render, obscure toggle, external control, validator |
| `login_screen_test.dart` | 8 | Render, validation, signIn call, error banner, forgot-password nav, unverified redirect |
| `signup_screen_test.dart` | 14 | Render, disabled button states, validation, signUp call, navigation, error banner, eye toggle, consent checkboxes |
| `email_verification_screen_test.dart` | 8 | Render, reset on mount, validation, verifyOtp, error banner, resend, back nav |
| `forgot_password_screen_test.dart` | 7 | Render, validation, requestPasswordReset, success view, error banner, back nav |
| `reset_password_screen_test.dart` | 8 | Render, validation, updatePassword, success view, error banner, eye toggle |
| `dashboard_screen_test.dart` | 6 | Greeting, stat cards, weekly goal, exercise section, training plan, level/duration |
| `main_shell_test.dart` | 5 | 4 nav destinations, app bar title, logout button, tab labels, first tab content |
| `greeting_header_test.dart` | 3 | Greeting key rendered, avatar first letter, empty name fallback |
| `stat_card_test.dart` | 2 | Label/value rendering, value color |
| `coming_soon_screen_test.dart` | 2 | Coming soon text, construction icon |

### Backend — 14 tests across 6 files

| File | Tests | Covers |
|------|-------|--------|
| `app.module.spec.ts` | 1 | Module instantiation |
| `jwt.strategy.spec.ts` | 2 | Missing env var, validate method |
| `consents.controller.spec.ts` | 3 | getConsents, upsertConsent, guards |
| `consents.service.spec.ts` | 4 | getConsents (success/error), upsertConsent (success/error) |
| `health.controller.spec.ts` | 2 | Instantiation, /health response |
| `supabase.service.spec.ts` | 2 | Missing env vars, getClient |

### Test Infrastructure

- **`test/helpers/test_app.dart`** — `pumpApp()` wraps widget in `ProviderScope` + `MaterialApp.router` + `EasyLocalization` with `_EmptyAssetLoader` (`.tr()` returns raw keys for assertion). Stub routes for all auth screens + all 4 tab paths (`/home/dashboard`, `/home/therapist`, `/home/mri-reader`, `/home/wellbeing`).
- **`test/helpers/mocks.dart`** — `FakeAuthNotifier` extends `AuthNotifier` with configurable errors and call tracking (`signInCalled`, `lastSignInEmail`, `signUpError`, etc.)
- **Pattern:** `mocktail` for mocking (no codegen), provider overrides via `overrideWith()`
- **Dashboard test isolation:** Override full consent chain (`authStateProvider`, `consentsProvider`, `hasTermsConsentProvider`, `hasPrivacyConsentProvider`, `hasAttConsentProvider`) to prevent `Supabase.instance` access

### Not Yet Covered

- Provider unit tests (AuthNotifier, ConsentProvider logic)
- Integration tests (full flow end-to-end)
- Deep link testing (requires device)
- JwtAuthGuard integration test
