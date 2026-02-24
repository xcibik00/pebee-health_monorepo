import { NotFoundException } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { SupabaseService } from '../supabase';

const mockProfileRow = {
  id: 'user-uuid-123',
  email: 'test@example.com',
  first_name: 'John',
  last_name: 'Doe',
  locale: 'en',
  created_at: '2024-01-01T00:00:00Z',
};

const createMockSupabaseService = (
  data: Record<string, unknown> | null,
  error: { message: string } | null = null,
): Partial<SupabaseService> => ({
  getClient: jest.fn().mockReturnValue({
    from: jest.fn().mockReturnValue({
      select: jest.fn().mockReturnValue({
        eq: jest.fn().mockReturnValue({
          single: jest.fn().mockResolvedValue({ data, error }),
        }),
      }),
    }),
  }),
});

describe('AuthService', () => {
  let service: AuthService;

  const setupModule = async (
    supabaseMock: Partial<SupabaseService>,
  ): Promise<TestingModule> => {
    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: SupabaseService, useValue: supabaseMock },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    return module;
  };

  it('should return a mapped Profile for a valid user', async () => {
    await setupModule(createMockSupabaseService(mockProfileRow));

    const profile = await service.getProfile('user-uuid-123');

    expect(profile).toEqual({
      id: 'user-uuid-123',
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      locale: 'en',
      createdAt: '2024-01-01T00:00:00Z',
    });
  });

  it('should throw NotFoundException when profile does not exist', async () => {
    await setupModule(
      createMockSupabaseService(null, { message: 'Row not found' }),
    );

    await expect(service.getProfile('missing-user')).rejects.toThrow(
      NotFoundException,
    );
  });

  it('should throw NotFoundException when Supabase returns an error', async () => {
    await setupModule(
      createMockSupabaseService(null, { message: 'Database error' }),
    );

    await expect(service.getProfile('user-uuid-123')).rejects.toThrow(
      NotFoundException,
    );
  });
});
