import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { RequestUser } from './types/jwt-payload.interface';
import type { Profile } from '@pebee/types';

const mockProfile: Profile = {
  id: 'user-uuid-123',
  email: 'test@example.com',
  firstName: 'John',
  lastName: 'Doe',
  locale: 'en',
  createdAt: '2024-01-01T00:00:00Z',
};

describe('AuthController', () => {
  let controller: AuthController;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [
        {
          provide: AuthService,
          useValue: {
            getProfile: jest.fn().mockResolvedValue(mockProfile),
          },
        },
      ],
    }).compile();

    controller = module.get<AuthController>(AuthController);
  });

  it('should return the user profile for GET /auth/me', async () => {
    const user: RequestUser = {
      userId: 'user-uuid-123',
      email: 'test@example.com',
    };

    const result = await controller.getMe(user);

    expect(result).toEqual(mockProfile);
  });
});
