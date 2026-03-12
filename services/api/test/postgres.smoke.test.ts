import assert from 'node:assert/strict';
import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process';
import { mkdtemp, rm, unlink, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';

import { initdb, postgres } from '@embedded-postgres/linux-x64';
import { Client, type Pool } from 'pg';
import request from 'supertest';

import { HeuristicAiService } from '../src/ai/heuristic-service.js';
import { createApp } from '../src/app.js';
import { PostgresAuthRepository } from '../src/auth/postgres-repository.js';
import { readEnv, type AppEnv } from '../src/config/env.js';
import { createDatabasePool } from '../src/db/client.js';
import { migrateDatabase } from '../src/db/migrate.js';
import { PostgresPlanningRepository } from '../src/planning/postgres-repository.js';

async function getAvailablePort(): Promise<number> {
  return await new Promise((resolve, reject) => {
    const server = createServer();
    server.listen(0, '127.0.0.1');
    server.on('error', reject);
    server.on('listening', () => {
      const address = server.address();
      if (!address || typeof address === 'string') {
        reject(new Error('Failed to resolve a dynamic port.'));
        return;
      }

      const { port } = address;
      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolve(port);
      });
    });
  });
}

function createSmokeEnv(databaseUrl: string): AppEnv {
  return readEnv({
    ...process.env,
    NODE_ENV: 'test',
    HOST: '127.0.0.1',
    PORT: '3000',
    DATABASE_URL: databaseUrl,
    DATABASE_SSL_MODE: 'disable',
    DATABASE_SCHEMA: 'public',
    DATABASE_MIGRATIONS_TABLE: 'schema_migrations',
  });
}

function createPostgresEnv(): NodeJS.ProcessEnv {
  const libDir = resolve(dirname(initdb), '..', 'lib');
  const ldLibraryPath = process.env.LD_LIBRARY_PATH
    ? `${libDir}:${process.env.LD_LIBRARY_PATH}`
    : libDir;

  return {
    ...process.env,
    LC_MESSAGES: 'C',
    LD_LIBRARY_PATH: ldLibraryPath,
  };
}

async function runCommand(
  command: string,
  args: string[],
  env: NodeJS.ProcessEnv,
): Promise<void> {
  await new Promise<void>((resolvePromise, reject) => {
    const child = spawn(command, args, { env });
    let logs = '';

    child.stdout.on('data', (chunk: Buffer | string) => {
      logs += typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    });
    child.stderr.on('data', (chunk: Buffer | string) => {
      logs += typeof chunk === 'string' ? chunk : chunk.toString('utf8');
    });
    child.on('error', reject);
    child.on('close', (code) => {
      if (code === 0) {
        resolvePromise();
        return;
      }

      reject(
        new Error(
          `Command failed (${code}): ${command} ${args.join(' ')}\n${logs}`,
        ),
      );
    });
  });
}

async function startPostgresServer(
  dataDir: string,
  port: number,
  env: NodeJS.ProcessEnv,
): Promise<ChildProcessWithoutNullStreams> {
  return await new Promise((resolvePromise, reject) => {
    const child = spawn(
      postgres,
      ['-D', dataDir, '-p', String(port), '-c', 'listen_addresses=127.0.0.1'],
      { env },
    );
    let logs = '';
    let settled = false;

    const handleOutput = (chunk: Buffer) => {
      const message = chunk.toString('utf8');
      logs += message;
      if (
        !settled &&
        message.includes('database system is ready to accept connections')
      ) {
        settled = true;
        resolvePromise(child);
      }
    };

    child.stdout.on('data', handleOutput);
    child.stderr.on('data', handleOutput);
    child.on('error', reject);
    child.on('close', (code) => {
      if (!settled) {
        reject(
          new Error(
            `postgres exited before becoming ready (${code ?? 'null'})\n${logs}`,
          ),
        );
      }
    });
  });
}

async function stopPostgresServer(
  child: ChildProcessWithoutNullStreams | null,
): Promise<void> {
  if (!child) {
    return;
  }

  await new Promise<void>((resolvePromise) => {
    child.once('exit', () => resolvePromise());
    child.kill('SIGINT');
  });
}

async function main(): Promise<void> {
  const databaseDir = await mkdtemp(join(tmpdir(), 'overview-api-smoke-'));
  const passwordFile = join(tmpdir(), `overview-api-smoke-password-${Date.now()}.txt`);
  const port = await getAvailablePort();
  const databaseName = 'overview_smoke';
  const postgresEnv = createPostgresEnv();

  let postgresProcess: ChildProcessWithoutNullStreams | null = null;
  let pool: Pool | null = null;

  try {
    await writeFile(passwordFile, 'postgres\n', 'utf8');
    await runCommand(
      initdb,
      [
        `--pgdata=${databaseDir}`,
        '--auth=password',
        '--username=postgres',
        `--pwfile=${passwordFile}`,
      ],
      postgresEnv,
    );

    postgresProcess = await startPostgresServer(databaseDir, port, postgresEnv);

    const adminClient = new Client({
      host: '127.0.0.1',
      port,
      database: 'postgres',
      user: 'postgres',
      password: 'postgres',
    });
    await adminClient.connect();
    await adminClient.query(`CREATE DATABASE ${databaseName}`);
    await adminClient.end();

    const env = createSmokeEnv(
      `postgresql://postgres:postgres@127.0.0.1:${port}/${databaseName}`,
    );
    pool = createDatabasePool(env);

    const appliedMigrations = await migrateDatabase(pool, env);
    assert.equal(appliedMigrations, 2);

    const migrationRows = await pool.query(
      `SELECT version FROM ${env.DATABASE_SCHEMA}.${env.DATABASE_MIGRATIONS_TABLE}`,
    );
    assert.deepEqual(migrationRows.rows, [{ version: '0001' }, { version: '0002' }]);

    const planningRepository = new PostgresPlanningRepository(pool, env);
    const app = createApp({
      aiService: new HeuristicAiService(planningRepository),
      authRepository: new PostgresAuthRepository(pool, env),
      planningRepository,
    });

    const registerResponse = await request(app)
      .post('/auth/register')
      .send({
        email: 'pg-smoke@example.com',
        password: 'Password123',
      })
      .expect(201);
    const authToken = (registerResponse.body as { token: string }).token;
    const authHeader = { Authorization: `Bearer ${authToken}` };
    assert.equal(
      (registerResponse.body as { user: { email: string } }).user.email,
      'pg-smoke@example.com',
    );

    await request(app)
      .post('/auth/login')
      .send({
        email: 'pg-smoke@example.com',
        password: 'Password123',
      })
      .expect(200);

    const scheduleResponse = await request(app)
      .post('/planning/schedules')
      .set(authHeader)
      .send({
        title: 'Production sync smoke',
        startAt: '2026-03-12T09:00:00.000Z',
        endAt: '2026-03-12T10:00:00.000Z',
        reminders: [],
      })
      .expect(201);
    const scheduleId = (scheduleResponse.body as { id: string }).id;

    await request(app)
      .patch(`/planning/schedules/${scheduleId}`)
      .set(authHeader)
      .send({
        title: 'Production sync smoke updated',
        durationMinutes: 75,
      })
      .expect(200);

    await request(app)
      .post('/planning/tasks')
      .set(authHeader)
      .send({
        title: 'Verify postgres-backed CRUD',
        plannedStartAt: '2026-03-12T13:00:00.000Z',
        dueAt: '2026-03-13T01:00:00.000Z',
        reminders: [],
      })
      .expect(201);

    const memoCreateResponse = await request(app)
      .post('/planning/memos')
      .set(authHeader)
      .send({
        title: 'Archive me',
        listId: 'inbox',
        reminders: [],
        sortOrder: 1,
      })
      .expect(201);
    const memoId = (memoCreateResponse.body as { id: string }).id;

    await request(app)
      .patch(`/planning/memos/${memoId}`)
      .set(authHeader)
      .send({
        status: 'archived',
        archivedAt: '2026-03-12T18:00:00.000Z',
      })
      .expect(200);

    await request(app).get('/planning/schedules').expect(401);

    const schedules = await request(app)
      .get('/planning/schedules')
      .set(authHeader)
      .expect(200);
    const tasks = await request(app)
      .get('/planning/tasks')
      .set(authHeader)
      .expect(200);
    const memos = await request(app)
      .get('/planning/memos')
      .set(authHeader)
      .expect(200);

    assert.equal((schedules.body as { items: unknown[] }).items.length, 1);
    assert.equal((tasks.body as { items: unknown[] }).items.length, 1);
    assert.equal((memos.body as { items: unknown[] }).items.length, 1);
    assert.equal(
      (memos.body as { items: Array<{ status: string }> }).items[0]?.status,
      'archived',
    );

    await request(app)
      .post('/ai/ingest/text')
      .send({ text: '周五上午 10 点到 11 点和设计师开会' })
      .expect(401);

    const ingestResponse = await request(app)
      .post('/ai/ingest/text')
      .set(authHeader)
      .send({ text: '周五上午 10 点到 11 点和设计师开会' })
      .expect(200);
    assert.equal(
      (ingestResponse.body as { suggestedType: string }).suggestedType,
      'schedule',
    );

    const askResponse = await request(app)
      .post('/ai/ask')
      .set(authHeader)
      .send({ question: 'What do I have this week?' })
      .expect(200);
    assert.match(
      (askResponse.body as { answer: string }).answer,
      /1 schedules.*1 tasks.*1 memos/,
    );

    console.log('Postgres smoke test passed');
  } finally {
    if (pool) {
      await pool.end();
    }
    await stopPostgresServer(postgresProcess);
    await unlink(passwordFile).catch(() => {});
    await rm(databaseDir, { recursive: true, force: true });
  }
}

await main();
