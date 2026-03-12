import { createHash, randomUUID } from 'node:crypto';

import { HttpError } from '../planning/errors.js';
import { hashPassword, verifyPassword } from './passwords.js';
import type {
  AuthRepository,
  AuthSession,
  AuthUser,
  LoginInput,
  RegisterInput,
} from './types.js';

interface StoredUser extends AuthUser {
  passwordHash: string;
}

function nowIso(): string {
  return new Date().toISOString();
}

function createSession(user: AuthUser): AuthSession {
  const token = randomUUID();
  return {
    token,
    user,
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
  };
}

export class InMemoryAuthRepository implements AuthRepository {
  private readonly usersByEmail = new Map<string, StoredUser>();
  private readonly sessionsByTokenHash = new Map<string, AuthSession>();

  async register(input: RegisterInput): Promise<AuthSession> {
    const email = input.email.trim().toLowerCase();
    if (this.usersByEmail.has(email)) {
      throw new HttpError(409, 'Email already registered');
    }

    const timestamp = nowIso();
    const user: StoredUser = {
      id: randomUUID(),
      email,
      createdAt: timestamp,
      updatedAt: timestamp,
      passwordHash: await hashPassword(input.password),
    };
    this.usersByEmail.set(email, user);

    const session = createSession(_toAuthUser(user));
    this.sessionsByTokenHash.set(_hashToken(session.token), session);
    return session;
  }

  async login(input: LoginInput): Promise<AuthSession> {
    const email = input.email.trim().toLowerCase();
    const user = this.usersByEmail.get(email);
    if (!user || !(await verifyPassword(input.password, user.passwordHash))) {
      throw new HttpError(401, 'Invalid email or password');
    }

    const session = createSession(_toAuthUser(user));
    this.sessionsByTokenHash.set(_hashToken(session.token), session);
    return session;
  }
}

function _toAuthUser(user: StoredUser): AuthUser {
  return {
    id: user.id,
    email: user.email,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

function _hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
