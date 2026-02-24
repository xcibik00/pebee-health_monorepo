import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

/**
 * Provides a Supabase client initialised with the secret API key.
 * Use `getClient()` to obtain the client for server-side DB queries.
 */
@Injectable()
export class SupabaseService implements OnModuleInit {
  private readonly logger = new Logger(SupabaseService.name);
  private client!: SupabaseClient;

  constructor(private readonly configService: ConfigService) {}

  onModuleInit(): void {
    const url = this.configService.get<string>('SUPABASE_URL');
    const secretKey = this.configService.get<string>(
      'SUPABASE_SECRET_KEY',
    );

    if (!url || !secretKey) {
      throw new Error(
        'Missing SUPABASE_URL or SUPABASE_SECRET_KEY environment variable',
      );
    }

    this.client = createClient(url, secretKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    this.logger.log('Supabase client initialised');
  }

  /** Returns the Supabase client (bypasses RLS). */
  getClient(): SupabaseClient {
    return this.client;
  }
}
