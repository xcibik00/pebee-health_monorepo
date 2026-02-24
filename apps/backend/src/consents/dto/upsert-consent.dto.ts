import { z } from 'zod';

/** Zod schema for the POST /consents request body. */
export const upsertConsentSchema = z.object({
  consentType: z.string().min(1),
  granted: z.boolean(),
  platform: z.enum(['ios', 'android']),
});

/** TypeScript type inferred from the Zod schema. */
export type UpsertConsentDto = z.infer<typeof upsertConsentSchema>;
