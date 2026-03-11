import { readEnv } from './config/env.js';
import { createApp } from './app.js';

const env = readEnv();
const app = createApp();

app.listen(env.PORT, env.HOST, () => {
  console.log(`Overview API listening on http://${env.HOST}:${env.PORT}`);
});
