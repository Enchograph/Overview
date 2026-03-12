import { once } from 'node:events';

import { createServerDependencies } from '../bootstrap.js';
import { readEnv } from '../config/env.js';
import { createDatabasePool } from '../db/client.js';
import { migrateDatabase } from '../db/migrate.js';
import { startEmbeddedPostgres } from '../db/embedded-postgres.js';

async function main(): Promise<void> {
  const embeddedPostgres = await startEmbeddedPostgres();
  const env = readEnv({
    ...process.env,
    DATABASE_URL: embeddedPostgres.databaseUrl,
  });
  const migrationPool = createDatabasePool(env);

  try {
    await migrateDatabase(migrationPool, env);
  } finally {
    await migrationPool.end();
  }

  const { app, pool } = createServerDependencies(env);
  const server = app.listen(env.PORT, env.HOST, () => {
    console.log(`Embedded PostgreSQL listening on ${embeddedPostgres.databaseUrl}`);
    console.log(`Overview API listening on http://${env.HOST}:${env.PORT}`);
  });

  const shutdown = async () => {
    server.close();
    await once(server, 'close');
    await pool.end();
    await embeddedPostgres.stop();
  };

  process.once('SIGINT', () => {
    void shutdown().then(() => {
      process.exit(0);
    });
  });

  process.once('SIGTERM', () => {
    void shutdown().then(() => {
      process.exit(0);
    });
  });
}

await main();
