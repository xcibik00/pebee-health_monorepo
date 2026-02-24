import { Test, TestingModule } from '@nestjs/testing';
import { ConsentsController } from './consents.controller';
import { ConsentsService } from './consents.service';
import { RequestUser } from '../auth';
import type { UserConsent } from '@pebee/types';

const mockConsent: UserConsent = {
  id: 'consent-uuid-1',
  userId: 'user-uuid-123',
  consentType: 'att',
  granted: true,
  platform: 'android',
  createdAt: '2024-01-01T00:00:00Z',
  updatedAt: '2024-01-01T00:00:00Z',
};

const mockUser: RequestUser = {
  userId: 'user-uuid-123',
  email: 'test@example.com',
};

describe('ConsentsController', () => {
  let controller: ConsentsController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [ConsentsController],
      providers: [
        {
          provide: ConsentsService,
          useValue: {
            getConsents: jest.fn().mockResolvedValue([mockConsent]),
            upsertConsent: jest.fn().mockResolvedValue(mockConsent),
          },
        },
      ],
    }).compile();

    controller = module.get<ConsentsController>(ConsentsController);
  });

  it('should return list of consents for GET /consents', async () => {
    const result = await controller.getConsents(mockUser);
    expect(result).toEqual([mockConsent]);
  });

  it('should return upserted consent for POST /consents', async () => {
    const result = await controller.upsertConsent(mockUser, {
      consentType: 'att',
      granted: true,
      platform: 'android',
    });
    expect(result).toEqual(mockConsent);
  });
});
