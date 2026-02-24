import { Injectable } from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';

/** Guard that enforces a valid Supabase JWT on protected routes. */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {}
