import { createHash, randomUUID } from 'node:crypto';

import type { Pool, QueryResultRow } from 'pg';

import type { AppEnv } from '../config/env.js';
import { HttpError } from '../planning/errors.js';
import { hashPassword, verifyPassword } from './passwords.js';
import type {
  AuthRepository,
  AuthSession,
  AuthUser,
  LoginInput,
  RegisterInput,
} from './types.js';

interface AuthUserRow extends QueryResultRow {
  id: string;
  email: string;
  password_hash: string;
  created_at: Date | string;
  updated_at: Date | string;
}

function quoteIdentifier(value: string): string {
  return `"${value.replaceAll('"', '""')}"`;
}

function buildTableName(env: AppEnv, name: string): string {
  return `${quoteIdentifier(env.DATABASE_SCHEMA)}.${quoteIdentifier(name)}`;
}

export class PostgresAuthRepository implements AuthRepository {
  private readonly usersTableName: string;
  private readonly sessionsTableName: string;

  constructor(
    private readonly pool: Pool,
    env: AppEnv,
  ) {
    this.usersTableName = buildTableName(env, 'users');
    this.sessionsTableName = buildTableName(env, 'auth_sessions');
  }

  async register(input: RegisterInput): Promise<AuthSession> {
    const email = input.email.trim().toLowerCase();
    const existing = await this.pool.query<{ id: string }>(
      `SELECT id FROM ${this.usersTableName} WHERE email = $1 LIMIT 1`,
      [email],
    );
    if (existing.rows.length > 0) {
      throw new HttpError(409, 'Email already registered');
    }

    const passwordHash = await hashPassword(input.password);
    const result = await this.pool.query<AuthUserRow>(
      `
        INSERT INTO ${this.usersTableName} (email, password_hash)
        VALUES ($1, $2)
        RETURNING id, email, password_hash, created_at, updated_at
      `,
      [email, passwordHash],
    );
    return this.createSession(_mapUser(result.rows[0]!));
  }

  async login(input: LoginInput): Promise<AuthSession> {
    const email = input.email.trim().toLowerCase();
    const result = await this.pool.query<AuthUserRow>(
      `
        SELECT id, email, password_hash, created_at, updated_at
        FROM ${this.usersTableName}
        WHERE email = $1
        LIMIT 1
      `,
      [email],
    );
    const user = result.rows[0];
    if (!user || !(await verifyPassword(input.password, user.password_hash))) {
      throw new HttpError(401, 'Invalid email or password');
    }

    return this.createSession(_mapUser(user));
  }

  async getUserForToken(token: string): Promise<AuthUser | null> {
    const result = await this.pool.query<AuthUserRow>(
      `
        SELECT u.id, u.email, u.password_hash, u.created_at, u.updated_at
        FROM ${this.sessionsTableName} s
        JOIN ${this.usersTableName} u ON u.id = s.user_id
        WHERE s.token_hash = $1
          AND s.revoked_at IS NULL
          AND s.expires_at > NOW()
        LIMIT 1
      `,
      [_hashToken(token)],
    );

    const row = result.rows[0];
    return row ? _mapUser(row) : null;
  }

  private async createSession(user: AuthUser): Promise<AuthSession> {
    const token = randomUUID();
    const expiresAt = new Date(
      Date.now() + 30 * 24 * 60 * 60 * 1000,
    ).toISOString();
    await this.pool.query(
      `
        INSERT INTO ${this.sessionsTableName} (
          id,
          user_id,
          token_hash,
          expires_at
        ) VALUES ($1, $2, $3, $4)
      `,
      [randomUUID(), user.id, _hashToken(token), expiresAt],
    );

    return {
      token,
      user,
      expiresAt,
    };
  }
}

function _mapUser(row: AuthUserRow): AuthUser {
  return {
    id: row.id,
    email: row.email,
    createdAt: new Date(row.created_at).toISOString(),
    updatedAt: new Date(row.updated_at).toISOString(),
  };
}

function _hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
