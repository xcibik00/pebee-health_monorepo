import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth';
import { ConsentsModule } from './consents';
import { HealthController } from './health/health.controller';
import { SupabaseModule } from './supabase';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SupabaseModule,
    AuthModule,
    ConsentsModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}
