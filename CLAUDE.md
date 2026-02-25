# CLAUDE.md — Project Context & Working Agreement

> This file is the single source of truth for Claude across all sessions.
> **Always read this file fully at the start of every session.**
> At the end of every session, update the relevant sections to reflect what was done.

---

## What This Project Is

A multi-platform product consisting of three interconnected parts:
- **Mobile app** — Flutter (iOS + Android, Huawei deferred post-MVP)
- **Web app** — Next.js 14 (App Router); customer-facing public site + superadmin panel
- **Backend** — NestJS (TypeScript); REST API, business logic, auth enforcement
- **Database** — Supabase (Postgres + Auth + Storage); accessed only through the backend except for auth token retrieval

---

## Repository Structure

```
root/                          ← monorepo, single git repo
├── CLAUDE.md                  ← this file (always read first)
├── PLANS/                     ← all plans and architecture docs
│   ├── 00-architecture.md
│   └── DECISIONS.md           ← Architecture Decision Records (ADRs)
├── apps/
│   ├── mobile/                ← Flutter app
│   ├── web/                   ← Next.js (customer + /admin route group)
│   └── backend/               ← NestJS API
├── packages/
│   └── types/                 ← shared TypeScript interfaces (web ↔ backend)
├── docker-compose.yml         ← local dev orchestration
└── .github/
    └── workflows/             ← CI/CD pipelines
```

---

## Tech Stack Decisions

| Layer | Technology | Notes |
|---|---|---|
| Mobile | Flutter (Dart) | Feature-first folder structure |
| Web | Next.js 14, App Router, TypeScript | Tailwind CSS for styling |
| Backend | NestJS, TypeScript | Module-per-domain architecture |
| Database | Supabase (Postgres) | Auth via Supabase, data via NestJS |
| Hosting | Docker + VPS (backend), Vercel (web) | docker-compose for local dev |
| Shared types | `/packages/types` | TypeScript interfaces shared across web/backend |

---

## Architecture Decisions

> Append new decisions here as they are made. Never delete old ones — mark as superseded if changed.

- Supabase client used **only** for auth token retrieval on client side; all data queries go through NestJS backend
- No `any` types in TypeScript anywhere in the codebase
- All API endpoints validated with Zod on the backend
- Secrets via environment variables only — never committed to git
- Docker Compose used for local dev; all services defined there
- **Package manager: pnpm** — chosen for monorepo efficiency; `pnpm-workspace.yaml` links `apps/*` and `packages/*`
- **Shared types package name: `@pebee/types`** — imported via `workspace:*` protocol in web and backend
- **`apps/mobile/` scaffold is complete** — `flutter create` was run; native iOS/Android project files exist
- **Do not scaffold web or backend with CLI interactively** — structure is already in place; use `pnpm install` to resolve deps
- **Flutter auth: repository pattern + Riverpod AsyncNotifier** — `AuthRepository` is the single Supabase boundary; `AuthNotifier` exposes async state; screens only import `auth_provider.dart` or `auth_repository.dart` (never `supabase_flutter`)
- **Typed domain exceptions in repository layer** — e.g. `EmailNotConfirmedException`, `ResendRateLimitedException`; UI detects these by type, never by string-matching error messages
- **Supabase OTP type for email verification: `OtpType.signup`** — used for both `verifyOTP` and `resend`; Supabase sends 8-digit codes (not 6)
- **User profile synced via Postgres trigger** — `handle_new_user()` on `auth.users` INSERT writes to `public.profiles`; metadata keys: `first_name`, `last_name`, `locale`
- **Locale default in profiles: `'en'`** — `COALESCE(raw_user_meta_data->>'locale', 'en')` in trigger
- **Widget test infrastructure** — `mocktail` for mocking (no codegen), `FakeAuthNotifier` pattern with configurable errors/call tracking, `_EmptyAssetLoader` so `.tr()` returns raw keys for assertion
- **Native splash via `flutter_native_splash`** — cream background (#F2EDE7) + full logo; `preserve()`/`remove()` in `main()` bridges to Flutter
- **Flutter splash route at `/` as `initialLocation`** — router redirect handles auth-loading state; prevents login-screen flash for returning users
- **App icon: golden bars on purple `#6B68E6`** — adaptive icon on Android, standard icon on iOS; generated via `flutter_launcher_icons`
- **Icon bars extracted as standalone SVG** — `assets/logo/icon_bars.svg` is the canonical source for the icon mark
- **Backend JWT verification via JWKS (ES256)** — Supabase migrated from HS256 to ES256 signing keys; backend uses `jwks-rsa` with `passportJwtSecret()` to fetch keys from `{SUPABASE_URL}/auth/v1/.well-known/jwks.json`; no static JWT_SECRET needed
- **Supabase API key naming** — `SUPABASE_PUBLISHABLE_KEY` (mobile, safe to embed), `SUPABASE_SECRET_KEY` (backend, never exposed); matches Supabase's new key naming convention; legacy JWT-based keys disabled
- **Platform-aware API base URL** — `ApiClient` auto-detects: Android emulator → `http://10.0.2.2:3001/api`, iOS simulator → `http://localhost:3001/api`; override via `API_BASE_URL` env var
- **Consent infrastructure** — `user_consents` table with `UNIQUE(user_id, consent_type)` constraint; types: `att`, `terms`, `privacy`; consent records created via `POST /consents` endpoint
- **ATT popup via `ref.listen` in `build()`** — Riverpod requires `ref.listen` inside `build()`, not in `initState()`; consentsProvider depends on authStateProvider to prevent 401s before login
- **T&C + Privacy checkboxes on signup** — required checkboxes with inline tappable links to placeholder URLs; consent records saved on home screen after first login; SQL migration for existing users
- **Android 12+ splash uses bars icon** — `app_icon_foreground.png` (bars only) for `android_12` config; full logo for pre-12 and iOS; prevents text clipping in 240dp circle
- **Signup button disabled until form complete** — `_isFormComplete` getter checks all 5 text fields non-empty + both consent checkboxes checked; controller listeners trigger `setState` for real-time button state; full validation still runs on tap
- **Language switcher: compact PopupMenuButton** — flag + ISO code chip opens dropdown with full language names + checkmark on active; replaces horizontal 4-button row; present on login, signup, forgot-password, and reset-password screens
- **Deep links via custom URL scheme `com.pebeehealth.mobile`** — registered in iOS `CFBundleURLTypes` (Info.plist) and Android intent-filter (AndroidManifest.xml); used by Supabase password reset redirect; `com.pebeehealth.mobile://reset-password` added to Supabase Redirect URLs
- **Password reset flow: client-side only** — no backend changes needed; `AuthRepository.resetPasswordForEmail()` → Supabase sends magic link email → deep link opens app → `AuthChangeEvent.passwordRecovery` detected by `passwordRecoveryProvider` → router redirects to `/reset-password` → `AuthRepository.updatePassword()` via `UserAttributes(password:)` → sign out → login; security (link expiry, single-use, rate limiting) handled entirely by Supabase
- **`passwordRecoveryProvider` (StreamProvider)** — watches `authStateChanges` for `AuthChangeEvent.passwordRecovery`; router's `_AuthStateListenable` also listens to this provider so redirect fires immediately on deep link

---

## Current Focus

> Update this at the start/end of every session.

**Status:** Full auth flow complete including password reset with deep links, all UX polish done (51 Flutter + 14 backend = 65 tests passing)
**Next up (Session 8):**
1. **Test reset password flow on device** — verify deep link opens app on both iOS and Android, full flow from "Forgot password?" to successful password change (implemented in Session 7, not yet tested on device)

**Backlog (noted, not yet planned):**
- **Consent withdrawal in Settings** — allow users to opt out of ATT/analytics from a settings screen (`granted: false`). T&C and privacy are mandatory (without them user cannot use the app), while ATT opt-out is OK (just disables analytics).
- **Firebase Analytics** — depends on ATT consent; deferred until ATT is implemented
- **User profile screen** — view/edit profile info, change locale, manage consents

---

## Completed

> Move items here when done, with brief notes.

### Session 1 — Initial planning
- Created `CLAUDE.md` (this file) as the working agreement and project context

### Session 2 — Architecture docs + monorepo scaffold
- Populated `PLANS/00-architecture.md` — full system architecture: topology diagram, per-app breakdown, security model, data flow, folder structure, conventions, MVP boundaries
- Created root `.gitignore` — covers Node, Flutter, iOS, Android, Docker, env files, IDE files
- Created `pnpm-workspace.yaml` — links `apps/*` and `packages/*`
- Created root `package.json` — top-level scripts for dev, build, lint, test, typecheck
- Created `docker-compose.yml` — backend service + Postgres (note: full Supabase local uses `supabase start` via CLI)
- Scaffolded `packages/types/` — `@pebee/types` package with `tsconfig.json`, `src/index.ts`, and starter `User` interface
- Scaffolded `apps/web/` — `package.json`, `tsconfig.json`, `.env.example`, route group structure `(public)/` and `(admin)/`
- Scaffolded `apps/backend/` — `package.json`, `tsconfig.json`, `.env.example`, `Dockerfile`, `src/main.ts`, `src/app.module.ts`
- Created `apps/mobile/.gitkeep` — placeholder pending `flutter create`

### Sessions 3 & 4 — Flutter mobile auth flow (complete)
**Auth screens & navigation**
- `LoginScreen` — email + password, error banner, language switcher top-right
- `SignupScreen` — first/last name, email, password + confirm (single shared eye icon), error banner
- `EmailVerificationScreen` — 8-digit OTP input, 5-attempt lock, 60s resend cooldown, rate-limit detection
- GoRouter auth guard — redirects unauthenticated users to `/login`, post-verify auto-redirect to `/home` via Supabase auth stream

**Auth logic (repository + provider)**
- `AuthRepository` — wraps all Supabase auth calls; rest of app never imports `supabase_flutter`
- Typed domain exceptions: `EmailNotConfirmedException` (unverified login), `ResendRateLimitedException` (429 on resend)
- `AuthNotifier` (Riverpod `AsyncNotifier`) — `signIn`, `signUp`, `verifyOtp`, `resendOtp`, `signOut`, `reset`
- Unverified user re-entry: login with unconfirmed email → `EmailNotConfirmedException` → auto-redirect to verification screen with email pre-filled

**Localisation**
- 4 languages: SK (default), EN, UK, DE — `assets/translations/*.json`
- `LanguageSwitcher` widget on login screen — flag + 2-char ISO code, animated active border
- Locale stored in Supabase `raw_user_meta_data` on signup for future localised Edge Function emails

**Database (Supabase)**
- `public.profiles` table: `id`, `email`, `first_name`, `last_name`, `locale`, `created_at`
- Postgres trigger `handle_new_user()` — fires on `auth.users` INSERT, syncs metadata into `profiles`
- RLS policies: users read/update own row; service role full access

**Debug tooling**
- `_AppProviderObserver` (debug-only, gated by `kDebugMode`) — logs all Riverpod `AsyncError`/`AsyncLoading`/`AsyncData` events with full stack traces to terminal

**Bug fixes this session**
- Stale error banner on verification screen on arrival from login → fixed with `reset()` post-frame in `initState`
- Silent resend failure → fixed with explicit error snackbars (`resendFailed`, `resendRateLimited`)
- 429 rate-limit on resend now starts the cooldown timer to block repeated hammering

### Session 6 — Backend scaffold + ATT consent + iOS setup + T&C checkboxes

**NestJS backend scaffold (fully working, 14 tests)**
- Module-per-domain architecture: `auth`, `consents`, `health`, `supabase` modules
- JWT auth guard using JWKS-based ES256 verification via `jwks-rsa` (no static secret needed)
- `SupabaseService` — wraps server-side Supabase client with secret key
- `ConsentsController` + `ConsentsService` — `GET /consents` (list user's consents), `POST /consents` (upsert consent record)
- `HealthController` — `GET /health` endpoint for monitoring
- Zod validation pipe for request body validation (`UpsertConsentDto`)
- `@CurrentUser()` decorator extracts user from JWT payload
- Logger-based error handling (no `console.log`)
- 14 unit tests across all modules, all passing

**ATT (App Tracking Transparency) consent**
- `TrackingConsentService` — shows in-app dialog explaining tracking, then triggers native iOS ATT popup
- `ConsentRepository` + `ConsentProvider` — fetches/saves consent records via backend API
- `consentsProvider` depends on `authStateProvider` to prevent 401 errors before login
- `ref.listen` in `HomeScreen.build()` triggers consent check when data loads
- `hasAttConsentProvider` — derived provider prevents popup on subsequent visits

**iOS development environment**
- CocoaPods updated, `pod install` run, iPhone simulator booted
- `ApiClient` made platform-aware: Android emulator uses `10.0.2.2`, iOS uses `localhost`
- Verified: splash, app icon, auth flow, ATT popup all working on iOS simulator

**Supabase API key migration**
- Discovered Supabase migrated from legacy HS256 JWT to ES256 signing keys
- Switched JWT strategy from static secret to JWKS endpoint verification
- Renamed env vars: `SUPABASE_SERVICE_ROLE_KEY` → `SUPABASE_SECRET_KEY`, `SUPABASE_ANON_KEY` → `SUPABASE_PUBLISHABLE_KEY`
- Removed `JWT_SECRET` — no longer needed with JWKS
- Legacy JWT-based API keys disabled in Supabase dashboard — everything still works

**App display name + cleanup**
- `CFBundleDisplayName` (iOS) and `android:label` (Android) changed from "Pebee Mobile"/"pebee_mobile" to "Pebee Health"
- Removed debug `debugPrint` logging from `ApiClient._buildHeaders()`

**Android splash screen fix**
- Android 12+ splash now uses `app_icon_foreground.png` (bars-only icon) instead of full logo that got clipped
- Pre-Android 12 and iOS keep the full `splash_logo.png` (works fine there)

**T&C + Privacy Policy checkboxes on signup (33 tests, all passing)**
- Two required checkboxes on signup screen with inline tappable links to placeholder URLs (`pebeehealth.com/terms`, `pebeehealth.com/privacy`)
- `_buildConsentCheckbox()` reusable widget with `TapGestureRecognizer` for link text, `GestureDetector` for label toggle
- Form submission blocked if either checkbox unchecked, with per-checkbox validation errors
- `hasTermsConsentProvider` + `hasPrivacyConsentProvider` derived providers in consent_provider.dart
- Home screen saves `terms` and `privacy` consent records via API on first login (auto-grants for existing users)
- 3 new widget tests: submit blocked without terms, submit blocked without privacy, submit succeeds with both checked
- Existing tests updated with `ensureVisible` for button visibility after checkbox addition
- Added `url_launcher: ^6.2.0` dependency (was already transitive)
- Translations added for all 4 languages (EN, SK, UK, DE)
- SQL migration run for existing users (backfill terms/privacy consent records)

**Bug fixes this session**
- `ref.listen can only be used within build()` — moved from `initState` post-frame callback to `build()` method
- 401 Unauthorized: `consentsProvider` firing before auth — added `authStateProvider` dependency, returns empty list when no user
- 401 persisting: JWT_SECRET wrong — Supabase had migrated to ES256; rewrote JWT strategy to use JWKS

### Session 7 — Visual parity, signup UX, language switcher, password reset

**iOS/Android visual parity**
- Added `centerTitle: true` to home screen AppBar — title now centered on both platforms
- Splash screen: confirmed Android 12+ 240dp circle is a Material 3 platform limitation; current bars-only icon for `android_12` is the correct approach

**Signup button disabled until form complete**
- `_isFormComplete` computed getter checks all 5 text fields non-empty + both consent checkboxes
- Controller listeners (`addListener`) on all 5 `TextEditingController`s trigger `setState` for real-time updates
- ElevatedButton `onPressed` is `null` when form incomplete or loading — button greyed out automatically
- Updated 14 signup widget tests to reflect disabled-button behavior

**Language switcher redesign**
- Rewrote `LanguageSwitcher` from horizontal 4-button row to compact `PopupMenuButton<Locale>`
- Trigger: flag + ISO code chip (e.g. "🇬🇧 EN" with dropdown arrow)
- Menu: 4 items with flag + full language name + checkmark on active language
- Added `name` field to `_Language` data model for display names (Slovenčina, English, Українська, Deutsch)
- Added `LanguageSwitcher` to signup screen AppBar `actions`
- Language switcher now present on all auth screens: login, signup, forgot-password, reset-password

**Reset password flow (51 Flutter tests, all passing)**
- `AuthRepository`: `resetPasswordForEmail()` (sends magic link with `redirectTo` to custom URL scheme), `updatePassword()` (calls `updateUser` with new password)
- `AuthNotifier`: `requestPasswordReset()`, `updatePassword()` methods
- `passwordRecoveryProvider` (StreamProvider) — watches for `AuthChangeEvent.passwordRecovery` events
- Deep link config: `CFBundleURLTypes` with `com.pebeehealth.mobile` scheme in Info.plist; intent-filter in AndroidManifest.xml
- Router: 2 new routes (`/forgot-password`, `/reset-password`), recovery redirect logic, `_AuthStateListenable` listens to both `authStateProvider` and `passwordRecoveryProvider`
- `ForgotPasswordScreen` — email input → success view with email icon + "Check your email" message, back button → login
- `ResetPasswordScreen` — new password + confirm (shared eye toggle via `PasswordField`), success view with check icon → sign out + go to login, back button (signs out + goes to login)
- Login screen: "Forgot password?" `TextButton` wired to `/forgot-password` (was `onPressed: null`)
- Translations: `forgotPassword.*` and `resetPassword.*` keys added to all 4 languages (EN, SK, UK, DE)
- `FakeAuthNotifier`: tracking for `requestPasswordReset` and `updatePassword` with configurable errors
- Test helper: `/forgot-password` and `/reset-password` stub routes added to `pumpApp`
- 7 forgot-password tests (render, validation, submit, success view, error banner, back navigation)
- 8 reset-password tests (render, validation, submit, success view, error banner, eye toggle)
- 1 new login test (forgot password navigation)
- Supabase config: `com.pebeehealth.mobile://reset-password` added to Redirect URLs (user action)
- **Not yet tested on device** — deep link flow needs manual testing on iOS/Android

### Session 5 — Widget tests + splash screen + app icon
**Widget tests (30 tests, all passing)**
- Test infrastructure: `test/helpers/test_app.dart` (`pumpApp` helper with EasyLocalization + GoRouter + Riverpod), `test/helpers/mocks.dart` (`FakeAuthNotifier`)
- `PasswordField` widget test — 6 tests (render, obscure, toggle, external control, validator)
- `LoginScreen` widget test — 7 tests (render, validation, signIn, error banner, EmailNotConfirmedException navigation)
- `SignupScreen` widget test — 8 tests (render, validation, signUp, navigation, error banner, eye icon toggle)
- `EmailVerificationScreen` widget test — 9 tests (render, reset on mount, validation, verifyOtp, error banner, resend, back navigation)
- Added `mocktail: ^1.0.4` and `shared_preferences: ^2.3.0` dev dependencies
- Deleted stale placeholder `test/widget_test.dart`

**Branded splash screen**
- Native splash via `flutter_native_splash` — cream background (#F2EDE7) + full Pebee Health logo (purple text + golden bars)
- `main.dart` uses `FlutterNativeSplash.preserve()`/`.remove()` to bridge native → Flutter splash
- Flutter-level `SplashScreen` at route `/` (new `initialLocation`) — same visual as native splash
- Router redirect updated: loading state → stay on splash; auth resolved → `/login` or `/home`; prevents login-screen flash for returning users

**App icon**
- Generated `icon_bars.svg` — standalone SVG with just the 3 golden bars, extracted from logo coordinates
- Converted SVGs to PNGs via `rsvg-convert` + `imagemagick`: `splash_logo.png` (1200x1200), `app_icon.png` (1024x1024, bars on purple), `app_icon_foreground.png` (adaptive icon)
- `flutter_launcher_icons` generates all iOS/Android icon sizes
- Android debug build verified successfully

---

## Session Protocol

### Start of session
1. Read this entire file
2. Review the relevant `PLANS/` file for today's work
3. Confirm current focus with the user before writing any code

### End of session
Update this file with:
- Any new architectural decisions → add to "Architecture Decisions"
- What was completed → move to "Completed" with brief notes
- Update "Current Focus" to reflect what's next
- Any new conventions or "do not do" rules discovered

**Trigger phrase:** When the user says *"wrap up the session"*, perform the above update automatically.

---

## Prompt Conventions

### PLAN: prefix
When a message starts with `PLAN:`, this means:
- **Do not write any code or modify any files**
- Think like a senior architect
- Lay out a detailed step-by-step plan: what files will be created/modified, what decisions need to be made, what risks exist
- Ask clarifying questions if needed
- Wait for explicit approval before proceeding
- After approval, write the plan to the appropriate `PLANS/` file before executing

### Role switching
You can be asked to switch roles mid-conversation:

- **Developer mode** (default) — implement features following all standards below
- **Reviewer mode** — triggered by *"switch to reviewer"*: review recent code as a senior engineer, post feedback as numbered PR comments referencing specific files/lines, flag anything that violates the DoD or principles below
- **Architect mode** — triggered by *"switch to architect"* or `PLAN:` prefix: think at system level, consider scalability and maintainability, suggest two approaches with tradeoffs before recommending one
- **QA mode** — triggered by *"switch to QA"*: review feature for missing test cases, edge cases, error states, and security gaps; produce a test checklist

---

## Engineering Principles

### Mindset
- Always think like both the developer implementing it **and** the engineer maintaining it 6 months later
- Prefer boring, readable code over clever code
- If an approach feels hacky, say so and suggest the right way — don't implement something you'd be embarrassed to review
- When uncertain between two approaches, present both with tradeoffs rather than silently picking one

### Security — Always Consider
- **Never trust client input** — validate everything on the backend with Zod
- **No secrets in code** — environment variables only, `.env` files gitignored
- Auth checks enforced on every protected route and endpoint — never assume the frontend handles it
- Sanitize all user-generated content before storing or rendering
- Use parameterized queries — never raw string interpolation in DB queries
- Flag any security concern explicitly, even if it's outside the current task scope

### Code Quality
- Human-readable variable and function names — spell things out, no abbreviations
- Functions do one thing; if a comment is needed to explain *what* it does (not *why*), it should be split or renamed
- Maximum ~40 lines per function; beyond that, suggest refactoring
- Every public service method and API endpoint has a JSDoc/dartdoc comment: purpose, params, return value, errors thrown
- No `console.log` left in committed code — use a proper logger
- No hardcoded values — use named constants or environment variables

### TypeScript Rules
- Strict mode enabled everywhere
- No `any` — ever. Use `unknown` and narrow it, or define the proper type
- Explicit return types on all functions
- Shared types live in `/packages/types` — never duplicate type definitions across apps

### Flutter/Dart Rules
- Feature-first folder structure: `lib/features/<feature_name>/`
- No business logic in widgets — use providers/blocs/cubits
- Handle loading, error, and empty states in every UI component
- Use `const` constructors wherever possible
- **Visual parity across iOS and Android** — every screen must look the same on both platforms. Always verify layout, alignment, and assets render identically. Use explicit alignment/centering rather than relying on platform defaults (e.g. `centerTitle: true` on AppBar)

---

## Definition of Done

A task or feature is **NOT done** until all of the following are true:

- [ ] Implementation complete and working
- [ ] **Unit tests** written for all business logic
- [ ] **Integration test** written for any new API endpoint
- [ ] **Widget test** written for any new Flutter UI component
- [ ] Error states handled — not just the happy path
- [ ] Input validated (Zod on backend, form validation on frontend/mobile)
- [ ] Auth/authorization enforced on any protected resource
- [ ] No `any` types, no `console.log`, no hardcoded values
- [ ] No secrets or sensitive data in code
- [ ] JSDoc/dartdoc comment on all public methods
- [ ] Reviewed against these principles (self-review or reviewer mode)

---

## What NOT to Do

- Don't modify `/apps/mobile/ios` or `/apps/mobile/android` manually — use Flutter CLI and tooling
- Don't add a new npm/pub dependency without flagging it to the user first
- Don't implement anything that hasn't been planned when the task was prefixed with `PLAN:`
- Don't write tests as an afterthought — they are part of the implementation
- Don't duplicate type definitions — always check `/packages/types` first
- Don't use `WidthType.PERCENTAGE` in any document generation (always DXA)
- Don't use `any` in TypeScript — if you're tempted to, define the type properly

---

## Key File Locations

| What | Where |
|---|---|
| Architecture plans | `PLANS/00-architecture.md` |
| Decision log | `PLANS/DECISIONS.md` |
| Shared types | `packages/types/` |
| Environment variable examples | `apps/backend/.env.example`, `apps/web/.env.example` |
| Local dev orchestration | `docker-compose.yml` |
| Flutter app entry point | `apps/mobile/lib/main.dart` |
| Flutter router | `apps/mobile/lib/core/router/app_router.dart` |
| Auth repository (Supabase boundary) | `apps/mobile/lib/features/auth/data/auth_repository.dart` |
| Auth provider (Riverpod state) | `apps/mobile/lib/features/auth/providers/auth_provider.dart` |
| Translations | `apps/mobile/assets/translations/` (sk, en, uk, de) |
| Theme & colours | `apps/mobile/lib/core/theme/` |
| Splash screen | `apps/mobile/lib/features/splash/presentation/screens/splash_screen.dart` |
| Logo assets (SVG + PNG) | `apps/mobile/assets/logo/` |
| Test helpers | `apps/mobile/test/helpers/` (test_app.dart, mocks.dart) |
| Backend entry point | `apps/backend/src/main.ts` |
| Backend app module | `apps/backend/src/app.module.ts` |
| JWT strategy (JWKS) | `apps/backend/src/auth/strategies/jwt.strategy.ts` |
| Supabase service (backend) | `apps/backend/src/supabase/supabase.service.ts` |
| Consents controller | `apps/backend/src/consents/consents.controller.ts` |
| API client (mobile) | `apps/mobile/lib/core/network/api_client.dart` |
| Consent repository (mobile) | `apps/mobile/lib/features/consent/data/consent_repository.dart` |
| Consent providers | `apps/mobile/lib/features/consent/providers/consent_provider.dart` |
| Tracking consent service | `apps/mobile/lib/features/consent/services/tracking_consent_service.dart` |
| Home screen | `apps/mobile/lib/features/home/presentation/screens/home_screen.dart` |
| Forgot password screen | `apps/mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart` |
| Reset password screen | `apps/mobile/lib/features/auth/presentation/screens/reset_password_screen.dart` |
| Language switcher (compact) | `apps/mobile/lib/core/widgets/language_switcher.dart` |

---

*Last updated: Session 7 — Visual parity, signup UX, language switcher, password reset*
