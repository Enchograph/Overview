import { Pool, type PoolConfig } from 'pg';

import type { AppEnv } from '../config/env.js';

export function getDatabaseConfig(env: AppEnv): PoolConfig {
  if (!env.DATABASE_URL) {
    throw new Error(
      'DATABASE_URL is required for database operations. Copy services/api/.env.example and configure PostgreSQL first.',
    );
  }

  return {
    connectionString: env.DATABASE_URL,
    ssl: env.DATABASE_SSL_MODE === 'require' ? { rejectUnauthorized: false } : false,
  };
}

export function createDatabasePool(env: AppEnv): Pool {
  return new Pool(getDatabaseConfig(env));
}
