// ─── UserConsent ──────────────────────────────────────────────────────────────

/** A consent record stored in `public.user_consents`. */
export interface UserConsent {
  id: string;
  userId: string;
  consentType: string;
  granted: boolean;
  platform: string;
  createdAt: string;
  updatedAt: string;
}
