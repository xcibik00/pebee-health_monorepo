# Architecture Decision Records (ADRs)

> Never delete entries. Mark superseded decisions with **[SUPERSEDED by ADR-NNN]**.

---

## ADR-001 — Monorepo with pnpm workspaces
**Date:** Session 2
**Status:** Accepted

**Decision:** Use a single git repository with pnpm workspaces to manage `apps/web`, `apps/backend`, and `packages/types` as linked packages.

**Rationale:** Simplifies cross-package type sharing, consistent tooling, and atomic commits across layers. pnpm chosen over npm/yarn for speed and disk efficiency in monorepos.

**Consequences:** All JS package management must use pnpm. Root `pnpm-workspace.yaml` links `apps/*` and `packages/*`.

---

## ADR-002 — Shared types via `@pebee/types`
**Date:** Session 2
**Status:** Accepted

**Decision:** All TypeScript interfaces shared between `apps/web` and `apps/backend` live exclusively in `packages/types`, published internally as `@pebee/types`.

**Rationale:** Prevents type drift between frontend and backend. Single source of truth. Imported via `workspace:*` protocol.

**Consequences:** Before defining any type in web or backend, check `packages/types` first. Dart models in Flutter are maintained separately until a codegen solution is adopted.

---

## ADR-003 — Supabase access boundary
**Date:** Session 1
**Status:** Accepted

**Decision:** Client applications (web, mobile) may only call Supabase for **auth token retrieval** (sign-in, token refresh). All data reads/writes go through the NestJS backend using a server-side Supabase client with the service role key.

**Rationale:** Keeps business logic centralised, prevents RLS bypass via client-side queries, protects the service role key.

**Consequences:** Backend holds `SUPABASE_SERVICE_ROLE_KEY`. Clients hold only `SUPABASE_URL` + `SUPABASE_ANON_KEY`. Never expose service role key to clients.

---

## ADR-004 — NestJS module-per-domain structure
**Date:** Session 2
**Status:** Accepted

**Decision:** Each business domain (e.g. auth, users, appointments) gets its own NestJS module directory under `apps/backend/src/<domain>/` containing: module, controller, service, DTOs, and spec file.

**Rationale:** Enforces separation of concerns, makes the codebase navigable, and mirrors the domain model.

**Consequences:** No cross-domain imports except through explicit module exports. Business logic lives in services, never in controllers.

---

## ADR-005 — Next.js App Router route groups
**Date:** Session 2
**Status:** Accepted

**Decision:** Web app uses two route groups: `(public)` for customer-facing pages and `(admin)` for the superadmin panel. Both live under `apps/web/src/app/`.

**Rationale:** Route groups allow separate layouts and auth middleware per section without affecting the URL structure.

**Consequences:** All admin routes must have auth enforcement at the middleware level in addition to backend JWT validation.

---

## ADR-006 — Flutter scaffold deferred
**Date:** Session 2
**Status:** **[SUPERSEDED by ADR-007]** — scaffold is now complete.

**Decision:** `apps/mobile/` is a placeholder. Proper scaffold must be done via `flutter create . --org com.pebeehealth --project-name pebee_mobile` inside `apps/mobile/` once Flutter SDK is installed.

**Rationale:** Flutter CLI generates native project files (iOS/Android) that should never be created or modified manually.

**Consequences:** Do not manually create files inside `apps/mobile/ios/` or `apps/mobile/android/`.

---

## ADR-007 — Flutter mobile scaffold complete
**Date:** Session 3
**Status:** Accepted

**Decision:** Flutter project is fully scaffolded and running. `flutter create` was executed; native iOS and Android project files exist under `apps/mobile/`.

**Rationale:** Supersedes ADR-006. Development on mobile can proceed without any additional CLI scaffolding steps.

**Consequences:** Never manually edit files under `apps/mobile/ios/` or `apps/mobile/android/`. Use Flutter CLI and tooling for any native changes.

---

## ADR-008 — Flutter auth: repository pattern + Riverpod AsyncNotifier
**Date:** Session 3
**Status:** Accepted

**Decision:** All Supabase auth calls are encapsulated in `AuthRepository`. The UI layer never imports `supabase_flutter` directly. Riverpod `AsyncNotifier<void>` (`AuthNotifier`) is the single source of async auth state consumed by screens.

**Rationale:** Enforces the Supabase access boundary (ADR-003) at the Dart level. Keeps UI code testable — screens depend on `AuthNotifier`, not on Supabase. `AsyncValue` gives loading/error/data states for free.

**Consequences:** Any new auth operation must be added to `AuthRepository` first, then exposed through `AuthNotifier`. Screens import `auth_provider.dart` or `auth_repository.dart` — never `supabase_flutter`.

---

## ADR-009 — Typed domain exceptions in the repository layer
**Date:** Session 3
**Status:** Accepted

**Decision:** `AuthRepository` converts Supabase-specific exceptions into typed domain exceptions (e.g. `EmailNotConfirmedException`, `ResendRateLimitedException`) before they leave the repository. UI detects error types via `is` checks, never by parsing error message strings.

**Rationale:** Decouples the UI from Supabase SDK internals. If Supabase changes an error message, only the repository needs updating. Type-safe exception handling is more reliable and readable.

**Consequences:** Every new error scenario that requires specific UI behaviour must have its own exception class defined at the top of `auth_repository.dart`. Generic `AuthException`s that need no special handling are re-thrown as-is.

---

## ADR-010 — Supabase OTP: 8-digit codes, `OtpType.signup`
**Date:** Session 3
**Status:** Accepted

**Decision:** Email verification uses `OtpType.signup` for both `verifyOTP` and `resend`. The expected code length is `8` digits (Supabase default). This is stored as `const int _otpLength = 8` in the verification screen.

**Rationale:** Supabase sends 8-digit OTP codes by default. The OTP length is configurable in the Supabase dashboard (Authentication → Settings → OTP Expiry). The `signup` OTP type covers both fresh signups and re-verification after app restart.

**Consequences:** If the OTP length is changed in Supabase, update `_otpLength` in `email_verification_screen.dart` and the `otpInvalid` validation message in all 4 translation files.

---

## ADR-011 — User profile synced via Postgres trigger
**Date:** Session 3
**Status:** Accepted

**Decision:** A `SECURITY DEFINER` trigger function `handle_new_user()` on `auth.users` INSERT writes a row to `public.profiles` with `id`, `email`, `first_name`, `last_name`, `locale` (defaulting to `'en'`), and `created_at`.

**Rationale:** Keeps profile data accessible in the public schema without requiring a separate API call after signup. Metadata stored in `raw_user_meta_data` during `signUp` is automatically promoted to the typed `profiles` table.

**Consequences:** If new profile fields are needed at signup time, they must be: (1) passed in `data` map during `signUp`, (2) added as a column in `public.profiles`, and (3) referenced in the trigger function. Any schema change requires a Supabase SQL migration.

---
