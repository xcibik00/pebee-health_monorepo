import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { UserConsent } from '@pebee/types';
import { CurrentUser, JwtAuthGuard, RequestUser } from '../auth';
import { ZodValidationPipe } from '../shared/pipes/zod-validation.pipe';
import { ConsentsService } from './consents.service';
import {
  UpsertConsentDto,
  upsertConsentSchema,
} from './dto/upsert-consent.dto';

@Controller('consents')
@UseGuards(JwtAuthGuard)
export class ConsentsController {
  constructor(private readonly consentsService: ConsentsService) {}

  /**
   * Returns all consent records for the authenticated user.
   */
  @Get()
  async getConsents(
    @CurrentUser() user: RequestUser,
  ): Promise<UserConsent[]> {
    return this.consentsService.getConsents(user.userId);
  }

  /**
   * Creates or updates a consent record for the authenticated user.
   *
   * @param dto - Validated request body (consentType, granted, platform)
   */
  @Post()
  async upsertConsent(
    @CurrentUser() user: RequestUser,
    @Body(new ZodValidationPipe(upsertConsentSchema)) dto: UpsertConsentDto,
  ): Promise<UserConsent> {
    return this.consentsService.upsertConsent(user.userId, dto);
  }
}
