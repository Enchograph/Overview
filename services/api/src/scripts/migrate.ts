import { createDatabasePool } from '../db/client.js';
import { migrateDatabase } from '../db/migrate.js';
import { readEnv } from '../config/env.js';

async function main(): Promise<void> {
  const env = readEnv();
  const pool = createDatabasePool(env);

  try {
    const appliedCount = await migrateDatabase(pool, env);
    console.log(`Database migrations complete. Applied ${appliedCount} migration(s).`);
  } finally {
    await pool.end();
  }
}

await main();
