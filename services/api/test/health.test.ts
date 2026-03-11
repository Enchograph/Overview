import { once } from 'node:events';
import { request } from 'node:http';
import assert from 'node:assert/strict';

import { createApiServer } from '../src/server.ts';

async function main() {
  const server = createApiServer();
  server.listen(0, '127.0.0.1');
  await once(server, 'listening');

  const address = server.address();
  assert.ok(address && typeof address === 'object');

  const response = await new Promise<{
    statusCode: number | undefined;
    body: string;
    headers: Record<string, string | string[] | undefined>;
  }>((resolve, reject) => {
    const req = request(
      {
        host: '127.0.0.1',
        port: address.port,
        path: '/health',
        method: 'GET',
      },
      (res) => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', (chunk) => {
          body += chunk;
        });
        res.on('end', () => {
          resolve({
            statusCode: res.statusCode,
            body,
            headers: res.headers,
          });
        });
      },
    );

    req.on('error', reject);
    req.end();
  });

  assert.equal(response.statusCode, 200);
  assert.match(String(response.headers['content-type']), /^application\/json/);

  const payload = JSON.parse(response.body) as {
    status: string;
    service: string;
    timestamp: string;
  };

  assert.equal(payload.status, 'ok');
  assert.equal(payload.service, 'api');
  assert.doesNotThrow(() => new Date(payload.timestamp));

  await new Promise<void>((resolve, reject) => {
    server.close((error) => {
      if (error) {
        reject(error);
        return;
      }

      resolve();
    });
  });

  console.log('API health test passed');
}

await main();
