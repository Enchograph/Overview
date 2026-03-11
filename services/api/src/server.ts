import { createServer, type IncomingMessage, type ServerResponse } from 'node:http';

import {
  createHealthResponse,
  type HealthResponse,
} from '../../../packages/shared/src/contracts.ts';

export function requestListener(req: IncomingMessage, res: ServerResponse): void {
  if (req.method === 'GET' && req.url === '/health') {
    const payload: HealthResponse = createHealthResponse();

    res.writeHead(200, { 'content-type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(payload));
    return;
  }

  res.writeHead(404, { 'content-type': 'application/json; charset=utf-8' });
  res.end(JSON.stringify({ error: 'Not Found' }));
}

export function createApiServer() {
  return createServer(requestListener);
}

