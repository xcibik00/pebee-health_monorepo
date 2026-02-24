/** Shape of the decoded Supabase JWT payload. */
export interface JwtPayload {
  /** User UUID */
  sub: string;
  email: string;
  /** Supabase role — typically 'authenticated' */
  role: string;
  aud: string;
  iat: number;
  exp: number;
}

/** Validated user object attached to request by JwtStrategy. */
export interface RequestUser {
  userId: string;
  email: string;
}
