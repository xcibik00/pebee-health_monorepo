import { Module } from '@nestjs/common';

@Module({
  imports: [
    // Domain modules will be registered here as they are created.
    // e.g. UsersModule, AuthModule, etc.
  ],
})
export class AppModule {}
