# Pebee Health — System Architecture

> This document is the authoritative architectural reference for the monorepo.
> Update it when structural decisions change. Record all decisions in `DECISIONS.md`.

---

## 1. Overview

Pebee Health is a multi-platform health product composed of three interconnected applications sharing a single backend and database layer.

```
┌─────────────────┐     ┌─────────────────┐
│   Mobile App    │     │    Web App      │
│  Flutter (iOS + │     │  Next.js 14     │
│   Android)      │     │  App Router     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │        REST API        │
         └──────────┬────────────┘
                    │
         ┌──────────▼────────────┐
         │       Backend         │
         │   NestJS (TypeScript) │
         └──────────┬────────────┘
                    │
         ┌──────────▼────────────┐
         │       Supabase        │
         │  Postgres + Auth +    │
         │      Storage          │
         └───────────────────────┘
```

---

## 2. Applications

### 2.1 Mobile App (`apps/mobile/`)
- **Framework:** Flutter (Dart)
- **Targets:** iOS, Android (Huawei deferred post-MVP)
- **Structure:** Feature-first folder layout under `lib/features/<feature_name>/`
- **State management:** Providers / Blocs / Cubits (no business logic in widgets)
- **Auth:** Retrieves Supabase auth token client-side; passes JWT in `Authorization` header to backend
- **All data:** Fetched from NestJS backend — never directly from Supabase

### 2.2 Web App (`apps/web/`)
- **Framework:** Next.js 14, App Router, TypeScript
- **Styling:** Tailwind CSS
- **Route groups:**
  - `(public)` — customer-facing marketing / product pages
  - `(admin)` — superadmin panel (protected)
- **Auth:** Same pattern as mobile — Supabase token passed to backend
- **All data:** Fetched from NestJS backend — never directly from Supabase

### 2.3 Backend (`apps/backend/`)
- **Framework:** NestJS (TypeScript)
- **Architecture:** Module-per-domain (one NestJS module per business domain)
- **API style:** REST
- **Validation:** Zod schemas on every incoming request body/param/query
- **Auth enforcement:** JWT guard on all protected endpoints; never assumed from the client
- **DB access:** Supabase Postgres via a server-side Supabase client (never exposes keys to clients)

---

## 3. Database Layer

- **Provider:** Supabase (managed Postgres)
- **Auth:** Supabase Auth (JWT issuance and session management)
- **Storage:** Supabase Storage (file/media uploads)
- **Access rules:**
  - **Client apps** may only call Supabase for auth token retrieval (sign-in, refresh)
  - **All other data access** is strictly through the NestJS backend
  - Row Level Security (RLS) should be configured as a defence-in-depth measure, but business logic lives in the backend

---

## 4. Shared Types (`packages/types/`)

- TypeScript interfaces and types shared between the web app and backend
- **Single source of truth** — never duplicate type definitions in individual apps
- Both `apps/web` and `apps/backend` import from this package
- Mobile (Dart) maintains its own equivalent models; keep them in sync manually until a codegen solution is adopted

---

## 5. Infrastructure & Deployment

| Environment | Backend | Web | Mobile |
|---|---|---|---|
| Local dev | Docker Compose | Next.js dev server | Flutter run |
| Production | Docker + VPS | Vercel | App Store / Play Store |

### Local Development
- All services defined in `docker-compose.yml` at the repo root
- Backend, database (or Supabase local), and any auxiliary services run via `docker compose up`
- Web and mobile connect to the local backend

### Production
- **Backend:** Dockerised container deployed to a VPS; image built from `apps/backend/Dockerfile`
- **Web:** Deployed to Vercel; connected to the production backend URL via environment variables
- **Mobile:** Distributed through App Store (iOS) and Google Play (Android)

---

## 6. Security Model

1. **Input validation** — Zod schemas validate all incoming data at the NestJS controller/pipe layer before it reaches service logic
2. **Authentication** — Supabase issues JWTs; the NestJS JWT guard verifies every request to a protected route
3. **Authorisation** — enforced in NestJS service/guard layer; client is never trusted for access decisions
4. **Secrets** — environment variables only; `.env` files are gitignored; `.env.example` files committed for reference
5. **Parameterised queries** — no raw string interpolation in any database query
6. **RLS** — Supabase Row Level Security configured as defence-in-depth (not as the primary access control)
7. **No `any` types** — TypeScript strict mode everywhere; `unknown` used where type is not yet determined

---

## 7. Folder Structure

```
root/
├── CLAUDE.md                        ← project context & working agreement
├── PLANS/
│   ├── 00-architecture.md           ← this file
│   └── DECISIONS.md                 ← Architecture Decision Records (ADRs)
├── apps/
│   ├── mobile/                      ← Flutter app
│   │   └── lib/
│   │       └── features/
│   │           └── <feature_name>/
│   │               ├── data/        ← repositories, data sources
│   │               ├── domain/      ← entities, use cases
│   │               └── presentation/← pages, widgets, state
│   ├── web/                         ← Next.js app
│   │   └── src/
│   │       └── app/
│   │           ├── (public)/        ← customer-facing pages
│   │           └── (admin)/         ← superadmin panel
│   └── backend/                     ← NestJS API
│       └── src/
│           └── <domain>/            ← one module per business domain
│               ├── <domain>.module.ts
│               ├── <domain>.controller.ts
│               ├── <domain>.service.ts
│               ├── dto/             ← Zod-validated request/response shapes
│               └── <domain>.spec.ts ← unit tests
├── packages/
│   └── types/                       ← shared TypeScript interfaces
├── docker-compose.yml
└── .github/
    └── workflows/                   ← CI/CD pipelines
```

---

## 8. Data Flow

### Authenticated Request (typical)
```
Client (Mobile / Web)
  │
  ├─ 1. Obtains JWT from Supabase Auth (sign-in / token refresh)
  │
  ├─ 2. Sends REST request to NestJS backend
  │       Headers: Authorization: Bearer <jwt>
  │       Body: validated by Zod on arrival
  │
  └─ NestJS Backend
        ├─ 3. JWT Guard verifies token with Supabase
        ├─ 4. Zod schema validates request payload
        ├─ 5. Service executes business logic
        ├─ 6. Queries Supabase Postgres (server-side client)
        └─ 7. Returns typed response
```

---

## 9. Key Conventions

| Convention | Rule |
|---|---|
| TypeScript | Strict mode, no `any`, explicit return types, shared types in `/packages/types` |
| NestJS modules | One module per business domain; controllers thin, logic in services |
| Validation | Zod on every endpoint — no unvalidated input reaches service layer |
| Logging | Use NestJS Logger (backend); no `console.log` in committed code |
| Constants | Named constants or env vars — no hardcoded values |
| Function size | Max ~40 lines per function; split or rename if a comment is needed to explain *what* it does |
| Tests | Written alongside implementation — not as an afterthought |
| Flutter widgets | Const constructors where possible; loading/error/empty states always handled |

---

## 10. MVP Scope Boundaries

- Huawei support: **deferred post-MVP**
- Codegen for shared types between TypeScript and Dart: **not yet adopted**
- All other platforms and features to be documented in `DECISIONS.md` as they are scoped

---

*Last updated: Session 1 — Initial architecture document populated from CLAUDE.md*
