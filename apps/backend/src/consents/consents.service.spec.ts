import { Test, TestingModule } from '@nestjs/testing';
import { ConsentsService } from './consents.service';
import { SupabaseService } from '../supabase';

const mockConsentRow = {
  id: 'consent-uuid-1',
  user_id: 'user-uuid-123',
  consent_type: 'att',
  granted: true,
  platform: 'android',
  created_at: '2024-01-01T00:00:00Z',
  updated_at: '2024-01-01T00:00:00Z',
};

describe('ConsentsService', () => {
  let service: ConsentsService;

  const setupModule = async (
    supabaseMock: Partial<SupabaseService>,
  ): Promise<TestingModule> => {
    const module = await Test.createTestingModule({
      providers: [
        ConsentsService,
        { provide: SupabaseService, useValue: supabaseMock },
      ],
    }).compile();

    service = module.get<ConsentsService>(ConsentsService);
    return module;
  };

  describe('getConsents', () => {
    it('should return mapped consent records', async () => {
      await setupModule({
        getClient: jest.fn().mockReturnValue({
          from: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              eq: jest.fn().mockReturnValue({
                returns: jest
                  .fn()
                  .mockResolvedValue({ data: [mockConsentRow], error: null }),
              }),
            }),
          }),
        }),
      });

      const result = await service.getConsents('user-uuid-123');

      expect(result).toEqual([
        {
          id: 'consent-uuid-1',
          userId: 'user-uuid-123',
          consentType: 'att',
          granted: true,
          platform: 'android',
          createdAt: '2024-01-01T00:00:00Z',
          updatedAt: '2024-01-01T00:00:00Z',
        },
      ]);
    });

    it('should return empty array on error', async () => {
      await setupModule({
        getClient: jest.fn().mockReturnValue({
          from: jest.fn().mockReturnValue({
            select: jest.fn().mockReturnValue({
              eq: jest.fn().mockReturnValue({
                returns: jest.fn().mockResolvedValue({
                  data: null,
                  error: { message: 'DB error' },
                }),
              }),
            }),
          }),
        }),
      });

      const result = await service.getConsents('user-uuid-123');
      expect(result).toEqual([]);
    });
  });

  describe('upsertConsent', () => {
    it('should upsert and return mapped consent', async () => {
      await setupModule({
        getClient: jest.fn().mockReturnValue({
          from: jest.fn().mockReturnValue({
            upsert: jest.fn().mockReturnValue({
              select: jest.fn().mockReturnValue({
                single: jest
                  .fn()
                  .mockResolvedValue({ data: mockConsentRow, error: null }),
              }),
            }),
          }),
        }),
      });

      const result = await service.upsertConsent('user-uuid-123', {
        consentType: 'att',
        granted: true,
        platform: 'android',
      });

      expect(result.consentType).toBe('att');
      expect(result.granted).toBe(true);
      expect(result.userId).toBe('user-uuid-123');
    });

    it('should throw on upsert error', async () => {
      await setupModule({
        getClient: jest.fn().mockReturnValue({
          from: jest.fn().mockReturnValue({
            upsert: jest.fn().mockReturnValue({
              select: jest.fn().mockReturnValue({
                single: jest.fn().mockResolvedValue({
                  data: null,
                  error: { message: 'Upsert failed' },
                }),
              }),
            }),
          }),
        }),
      });

      await expect(
        service.upsertConsent('user-uuid-123', {
          consentType: 'att',
          granted: true,
          platform: 'android',
        }),
      ).rejects.toThrow('Failed to save consent');
    });
  });
});
