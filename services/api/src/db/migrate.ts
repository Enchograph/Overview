import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import type { Pool } from 'pg';

import type { AppEnv } from '../config/env.js';

interface MigrationFile {
  version: string;
  name: string;
  filename: string;
  sql: string;
}

const currentDir = path.dirname(fileURLToPath(import.meta.url));
const migrationsDir = path.resolve(currentDir, 'migrations');

function quoteIdentifier(value: string): string {
  return `"${value.replaceAll('"', '""')}"`;
}

async function loadMigrationFiles(): Promise<MigrationFile[]> {
  const files = (await readdir(migrationsDir))
    .filter((file) => file.endsWith('.sql'))
    .sort((left, right) => left.localeCompare(right));

  return Promise.all(
    files.map(async (filename) => {
      const [version, ...nameParts] = filename.replace(/\.sql$/u, '').split('_');

      if (!version || nameParts.length === 0) {
        throw new Error(`Invalid migration filename: ${filename}`);
      }

      return {
        version,
        name: nameParts.join('_'),
        filename,
        sql: await readFile(path.join(migrationsDir, filename), 'utf8'),
      };
    }),
  );
}

async function ensureMigrationTable(pool: Pool, env: AppEnv): Promise<void> {
  const schemaSql = quoteIdentifier(env.DATABASE_SCHEMA);
  const tableSql = quoteIdentifier(env.DATABASE_MIGRATIONS_TABLE);

  await pool.query(`CREATE SCHEMA IF NOT EXISTS ${schemaSql}`);
  await pool.query(`
    CREATE TABLE IF NOT EXISTS ${schemaSql}.${tableSql} (
      version TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
}

async function readAppliedVersions(
  pool: Pool,
  env: AppEnv,
): Promise<Set<string>> {
  const schemaSql = quoteIdentifier(env.DATABASE_SCHEMA);
  const tableSql = quoteIdentifier(env.DATABASE_MIGRATIONS_TABLE);
  const result = await pool.query<{ version: string }>(
    `SELECT version FROM ${schemaSql}.${tableSql} ORDER BY version ASC`,
  );

  return new Set(result.rows.map((row) => row.version));
}

export async function migrateDatabase(pool: Pool, env: AppEnv): Promise<number> {
  await ensureMigrationTable(pool, env);

  const appliedVersions = await readAppliedVersions(pool, env);
  const migrations = await loadMigrationFiles();

  let appliedCount = 0;

  for (const migration of migrations) {
    if (appliedVersions.has(migration.version)) {
      continue;
    }

    const client = await pool.connect();

    try {
      await client.query('BEGIN');
      await client.query(migration.sql);
      await client.query(
        `
          INSERT INTO ${quoteIdentifier(env.DATABASE_SCHEMA)}.${quoteIdentifier(env.DATABASE_MIGRATIONS_TABLE)} (
            version,
            name
          ) VALUES ($1, $2)
        `,
        [migration.version, migration.name],
      );
      await client.query('COMMIT');
      appliedCount += 1;
    } catch (error) {
      await client.query('ROLLBACK');
      throw new Error(
        `Failed to apply migration ${migration.filename}: ${error instanceof Error ? error.message : String(error)}`,
      );
    } finally {
      client.release();
    }
  }

  return appliedCount;
}
