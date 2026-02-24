import { Injectable, Logger } from '@nestjs/common';
import { UserConsent } from '@pebee/types';
import { SupabaseService } from '../supabase';
import { UpsertConsentDto } from './dto/upsert-consent.dto';

/** Row shape returned by Supabase from `public.user_consents`. */
interface ConsentRow {
  id: string;
  user_id: string;
  consent_type: string;
  granted: boolean;
  platform: string;
  created_at: string;
  updated_at: string;
}

/**
 * Manages user consent records in `public.user_consents`.
 */
@Injectable()
export class ConsentsService {
  private readonly logger = new Logger(ConsentsService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Returns all consent records for a user.
   *
   * @param userId - The Supabase auth user UUID
   * @returns Array of consent records (may be empty)
   */
  async getConsents(userId: string): Promise<UserConsent[]> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('user_consents')
      .select('*')
      .eq('user_id', userId)
      .returns<ConsentRow[]>();

    if (error) {
      this.logger.error(`Failed to fetch consents for ${userId}: ${error.message}`);
      return [];
    }

    return (data ?? []).map(this.mapRowToConsent);
  }

  /**
   * Creates or updates a consent record for a user.
   * Uses Supabase upsert on the (user_id, consent_type) unique constraint.
   *
   * @param userId - The Supabase auth user UUID
   * @param dto - The consent data (consentType, granted, platform)
   * @returns The upserted consent record
   */
  async upsertConsent(
    userId: string,
    dto: UpsertConsentDto,
  ): Promise<UserConsent> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('user_consents')
      .upsert(
        {
          user_id: userId,
          consent_type: dto.consentType,
          granted: dto.granted,
          platform: dto.platform,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,consent_type' },
      )
      .select('*')
      .single<ConsentRow>();

    if (error || !data) {
      this.logger.error(`Failed to upsert consent for ${userId}: ${error?.message}`);
      throw new Error(`Failed to save consent: ${error?.message}`);
    }

    return this.mapRowToConsent(data);
  }

  /** Maps a snake_case DB row to a camelCase UserConsent. */
  private mapRowToConsent(row: ConsentRow): UserConsent {
    return {
      id: row.id,
      userId: row.user_id,
      consentType: row.consent_type,
      granted: row.granted,
      platform: row.platform,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }
}
