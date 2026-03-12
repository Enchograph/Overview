import { spawn, type ChildProcessWithoutNullStreams } from 'node:child_process';
import { mkdtemp, rm, unlink, writeFile } from 'node:fs/promises';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';

import { initdb, postgres } from '@embedded-postgres/linux-x64';
import { Client } from 'pg';

export interface EmbeddedPostgresInstance {
  dataDir: string;
  databaseName: string;
  databaseUrl: string;
  port: number;
  stop: () => Promise<void>;
}

async function getAvailablePort(): Promise<number> {
  return await new Promise((resolvePromise, reject) => {
    const server = createServer();
    server.listen(0, '127.0.0.1');
    server.on('error', reject);
    server.on('listening', () => {
      const address = server.address();
      if (!address || typeof address === 'string') {
        reject(new Error('Failed to resolve an embedded PostgreSQL port.'));
        return;
      }

      server.close((error) => {
        if (error) {
          reject(error);
          return;
        }

        resolvePromise(address.port);
      });
    });
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
          `Embedded PostgreSQL command failed (${code}): ${command} ${args.join(' ')}\n${logs}`,
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
            `Embedded PostgreSQL exited before becoming ready (${code ?? 'null'})\n${logs}`,
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

export async function startEmbeddedPostgres(
  databaseName = 'overview_dev',
): Promise<EmbeddedPostgresInstance> {
  const dataDir = await mkdtemp(join(tmpdir(), 'overview-api-dev-'));
  const passwordFile = join(
    tmpdir(),
    `overview-api-dev-password-${Date.now()}.txt`,
  );
  const port = await getAvailablePort();
  const postgresEnv = createPostgresEnv();

  let postgresProcess: ChildProcessWithoutNullStreams | null = null;

  try {
    await writeFile(passwordFile, 'postgres\n', 'utf8');
    await runCommand(
      initdb,
      [
        `--pgdata=${dataDir}`,
        '--auth=password',
        '--username=postgres',
        `--pwfile=${passwordFile}`,
      ],
      postgresEnv,
    );

    postgresProcess = await startPostgresServer(dataDir, port, postgresEnv);

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

    return {
      dataDir,
      databaseName,
      databaseUrl: `postgresql://postgres:postgres@127.0.0.1:${port}/${databaseName}`,
      port,
      stop: async () => {
        await stopPostgresServer(postgresProcess);
        await Promise.allSettled([
          rm(dataDir, { recursive: true, force: true }),
          unlink(passwordFile),
        ]);
      },
    };
  } catch (error) {
    await stopPostgresServer(postgresProcess);
    await Promise.allSettled([
      rm(dataDir, { recursive: true, force: true }),
      unlink(passwordFile),
    ]);
    throw error;
  }
}
