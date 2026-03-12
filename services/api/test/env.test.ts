import assert from 'node:assert/strict';

import { readEnv } from '../src/config/env.js';

const env = readEnv({
  HOST: '127.0.0.1',
  PORT: '3000',
  NODE_ENV: 'development',
  DATABASE_URL: 'postgres://postgres:postgres@127.0.0.1:5432/overview',
  DATABASE_SSL_MODE: 'disable',
  DATABASE_SCHEMA: 'public',
  DATABASE_MIGRATIONS_TABLE: 'schema_migrations',
  AI_PROVIDER: 'auto',
  OPENAI_API_KEY: '   ',
  OPENAI_MODEL: 'gpt-4.1-mini',
  AZURE_SPEECH_KEY: '',
  AZURE_SPEECH_REGION: '   ',
  AZURE_SPEECH_LOCALE: 'zh-CN',
});

assert.equal(env.OPENAI_API_KEY, undefined);
assert.equal(env.AZURE_SPEECH_KEY, undefined);
assert.equal(env.AZURE_SPEECH_REGION, undefined);
