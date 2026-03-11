import express, { type Express } from 'express';

import { apiRouter } from './routes/index.js';

export function createApp(): Express {
  const app = express();

  app.use(express.json());
  app.use(apiRouter);

  app.use((_req, res) => {
    res.status(404).json({ error: 'Not Found' });
  });

  return app;
}
