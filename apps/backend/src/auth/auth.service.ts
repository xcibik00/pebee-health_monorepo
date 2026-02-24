import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { Profile } from '@pebee/types';
import { SupabaseService } from '../supabase';

/** Row shape returned by Supabase from `public.profiles`. */
interface ProfileRow {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  locale: string;
  created_at: string;
}

/**
 * Handles auth-related business logic (profile retrieval).
 * Supabase Auth itself is handled client-side; this service
 * uses the service-role client for server-side DB queries.
 */
@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Fetches the user profile from `public.profiles`.
   *
   * @param userId - The Supabase auth user UUID
   * @returns The user's profile with camelCase keys
   * @throws NotFoundException if no profile exists for the given userId
   */
  async getProfile(userId: string): Promise<Profile> {
    const { data, error } = await this.supabaseService
      .getClient()
      .from('profiles')
      .select('id, email, first_name, last_name, locale, created_at')
      .eq('id', userId)
      .single<ProfileRow>();

    if (error || !data) {
      this.logger.warn(`Profile not found for user ${userId}: ${error?.message}`);
      throw new NotFoundException(`Profile not found for user ${userId}`);
    }

    return {
      id: data.id,
      email: data.email,
      firstName: data.first_name,
      lastName: data.last_name,
      locale: data.locale,
      createdAt: data.created_at,
    };
  }
}
