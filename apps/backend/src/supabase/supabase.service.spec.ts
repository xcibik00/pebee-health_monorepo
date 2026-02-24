import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { SupabaseService } from './supabase.service';

describe('SupabaseService', () => {
  const createModule = async (
    envOverrides: Record<string, string | undefined> = {},
  ): Promise<TestingModule> => {
    const env: Record<string, string | undefined> = {
      SUPABASE_URL: 'https://test.supabase.co',
      SUPABASE_SECRET_KEY: 'test-service-role-key',
      ...envOverrides,
    };

    return Test.createTestingModule({
      providers: [
        SupabaseService,
        {
          provide: ConfigService,
          useValue: {
            get: (key: string): string | undefined => env[key],
          },
        },
      ],
    }).compile();
  };

  it('should initialise the Supabase client with valid env vars', async () => {
    const module = await createModule();
    const service = module.get<SupabaseService>(SupabaseService);

    // onModuleInit is called manually in tests
    service.onModuleInit();

    expect(service.getClient()).toBeDefined();
  });

  it('should throw when SUPABASE_URL is missing', async () => {
    const module = await createModule({ SUPABASE_URL: undefined });
    const service = module.get<SupabaseService>(SupabaseService);

    expect(() => service.onModuleInit()).toThrow(
      'Missing SUPABASE_URL or SUPABASE_SECRET_KEY',
    );
  });

  it('should throw when SUPABASE_SECRET_KEY is missing', async () => {
    const module = await createModule({
      SUPABASE_SECRET_KEY: undefined,
    });
    const service = module.get<SupabaseService>(SupabaseService);

    expect(() => service.onModuleInit()).toThrow(
      'Missing SUPABASE_URL or SUPABASE_SECRET_KEY',
    );
  });
});
