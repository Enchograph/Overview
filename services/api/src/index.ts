import { readEnv } from './config/env.js';
import { createServerDependencies } from './bootstrap.js';

const env = readEnv();
const { app } = createServerDependencies(env);

app.listen(env.PORT, env.HOST, () => {
  console.log(`Overview API listening on http://${env.HOST}:${env.PORT}`);
});
