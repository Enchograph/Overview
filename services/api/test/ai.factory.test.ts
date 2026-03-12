import assert from 'node:assert/strict';

import { createAiService } from '../src/ai/factory.js';
import { InMemoryPlanningRepository } from '../src/planning/memory-repository.js';
import type { AppEnv } from '../src/config/env.js';

function buildEnv(overrides: Partial<AppEnv> = {}): AppEnv {
  return {
    NODE_ENV: 'test',
    HOST: '127.0.0.1',
    PORT: 3000,
    DATABASE_URL: undefined,
    DATABASE_SSL_MODE: 'disable',
    DATABASE_SCHEMA: 'public',
    DATABASE_MIGRATIONS_TABLE: 'schema_migrations',
    AI_PROVIDER: 'auto',
    OPENAI_API_KEY: undefined,
    OPENAI_MODEL: 'gpt-4.1-mini',
    AZURE_SPEECH_KEY: undefined,
    AZURE_SPEECH_REGION: undefined,
    AZURE_SPEECH_LOCALE: 'zh-CN',
    ...overrides,
  };
}

async function main() {
  const repository = new InMemoryPlanningRepository();

  const heuristicService = createAiService(buildEnv(), repository);
  const heuristicResult = await heuristicService.ingestText(
    'user-1',
    '记得买猫粮',
  );
  assert.equal(heuristicResult.suggestedType, 'memo');

  assert.throws(
    () =>
      createAiService(
        buildEnv({
          AI_PROVIDER: 'openai',
          OPENAI_API_KEY: undefined,
        }),
        repository,
      ),
    /OPENAI_API_KEY is required/,
  );

  console.log('AI factory tests passed');
}

await main();
