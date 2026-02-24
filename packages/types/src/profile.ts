// ─── Profile ──────────────────────────────────────────────────────────────────

/** User profile synced from auth.users via Postgres trigger. */
export interface Profile {
  id: string;
  email: string;
  firstName: string;
  lastName: string;
  locale: string;
  createdAt: string;
}
