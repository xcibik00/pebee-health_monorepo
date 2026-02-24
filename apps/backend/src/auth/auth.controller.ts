import { Controller, Get, UseGuards } from '@nestjs/common';
import { Profile } from '@pebee/types';
import { AuthService } from './auth.service';
import { CurrentUser } from './decorators/current-user.decorator';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import { RequestUser } from './types/jwt-payload.interface';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Returns the authenticated user's profile.
   *
   * @param user - Injected by JwtAuthGuard + @CurrentUser()
   * @returns The user's profile from `public.profiles`
   */
  @Get('me')
  @UseGuards(JwtAuthGuard)
  async getMe(@CurrentUser() user: RequestUser): Promise<Profile> {
    return this.authService.getProfile(user.userId);
  }
}
