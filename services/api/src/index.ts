import { HeuristicAiService } from './ai/heuristic-service.js';
import { PostgresAuthRepository } from './auth/postgres-repository.js';
import { readEnv } from './config/env.js';
import { createDatabasePool } from './db/client.js';
import { PostgresPlanningRepository } from './planning/postgres-repository.js';
import { createApp } from './app.js';

const env = readEnv();
const pool = createDatabasePool(env);
const planningRepository = new PostgresPlanningRepository(pool, env);
const app = createApp({
  aiService: new HeuristicAiService(planningRepository),
  authRepository: new PostgresAuthRepository(pool, env),
  planningRepository,
});

app.listen(env.PORT, env.HOST, () => {
  console.log(`Overview API listening on http://${env.HOST}:${env.PORT}`);
});
