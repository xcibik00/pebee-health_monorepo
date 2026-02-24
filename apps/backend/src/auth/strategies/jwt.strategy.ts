import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { passportJwtSecret } from 'jwks-rsa';
import { JwtPayload, RequestUser } from '../types/jwt-payload.interface';

/**
 * Validates Supabase-issued JWTs from the Authorization header.
 * Fetches the signing key from Supabase's JWKS endpoint so it works
 * with both legacy HS256 and migrated ES256 signing keys.
 * On success, attaches `{ userId, email }` to `request.user`.
 */
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy, 'jwt') {
  constructor(configService: ConfigService) {
    const supabaseUrl = configService.get<string>('SUPABASE_URL');
    if (!supabaseUrl) {
      throw new Error('Missing SUPABASE_URL environment variable');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKeyProvider: passportJwtSecret({
        jwksUri: `${supabaseUrl}/auth/v1/.well-known/jwks.json`,
        cache: true,
        rateLimit: true,
        jwksRequestsPerMinute: 5,
      }),
      algorithms: ['ES256'],
    });
  }

  /** Called after JWT verification succeeds. */
  validate(payload: JwtPayload): RequestUser {
    return { userId: payload.sub, email: payload.email };
  }
}
