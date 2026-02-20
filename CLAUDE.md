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

---

## Current Focus

> Update this at the start/end of every session.

**Status:** Project setup / initial planning phase  
**Next up:** Scaffold monorepo structure, initialize apps, configure docker-compose

---

## Completed

> Move items here when done, with brief notes.

*(nothing yet)*

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

---

*Last updated: Session 1 — Initial project setup & planning*
