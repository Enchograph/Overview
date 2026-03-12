import { config as loadDotEnv } from 'dotenv';
import { z } from 'zod';

loadDotEnv();

const optionalTrimmedString = z.preprocess((value) => {
  if (typeof value !== 'string') {
    return value;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}, z.string().min(1).optional());

const envSchema = z.object({
  NODE_ENV: z
    .enum(['development', 'test', 'production'])
    .default('development'),
  HOST: z.string().trim().min(1).default('127.0.0.1'),
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  DATABASE_URL: z.string().trim().url().optional(),
  DATABASE_SSL_MODE: z.enum(['disable', 'require']).default('disable'),
  DATABASE_SCHEMA: z.string().trim().min(1).default('public'),
  DATABASE_MIGRATIONS_TABLE: z.string().trim().min(1).default('schema_migrations'),
  AI_PROVIDER: z.enum(['auto', 'heuristic', 'openai']).default('auto'),
  AI_SPEECH_PROVIDER: z.enum(['none', 'azure']).default('azure'),
  OPENAI_API_KEY: optionalTrimmedString,
  OPENAI_MODEL: z.string().trim().min(1).default('gpt-4.1-mini'),
  AZURE_SPEECH_KEY: optionalTrimmedString,
  AZURE_SPEECH_REGION: optionalTrimmedString,
  AZURE_SPEECH_LOCALE: z.string().trim().min(2).max(20).default('zh-CN'),
});

export type AppEnv = z.infer<typeof envSchema>;

export function readEnv(source: NodeJS.ProcessEnv = process.env): AppEnv {
  return envSchema.parse(source);
}
