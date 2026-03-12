import { createAiService } from './ai/factory.js';
import { PostgresAuthRepository } from './auth/postgres-repository.js';
import type { AppEnv } from './config/env.js';
import { createDatabasePool } from './db/client.js';
import { PostgresPlanningRepository } from './planning/postgres-repository.js';
import { createApp } from './app.js';

export function createServerDependencies(env: AppEnv) {
  const pool = createDatabasePool(env);
  const planningRepository = new PostgresPlanningRepository(pool, env);

  return {
    app: createApp({
      aiService: createAiService(env, planningRepository),
      authRepository: new PostgresAuthRepository(pool, env),
      planningRepository,
    }),
    pool,
  };
}
