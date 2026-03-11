import { createApiServer } from './server.ts';

const port = Number.parseInt(process.env.PORT ?? '3000', 10);
const host = process.env.HOST ?? '127.0.0.1';

const server = createApiServer();

server.listen(port, host, () => {
  console.log(`Overview API listening on http://${host}:${port}`);
});

