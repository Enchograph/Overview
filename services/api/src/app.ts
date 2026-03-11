import express, { type Express } from 'express';

import type { PlanningRepository } from './planning/types.js';
import { createApiRouter } from './routes/index.js';

export interface AppDependencies {
  planningRepository: PlanningRepository;
}

export function createApp(dependencies: AppDependencies): Express {
  const app = express();

  app.use(express.json());
  app.use(createApiRouter(dependencies.planningRepository));

  app.use((_req, res) => {
    res.status(404).json({ error: 'Not Found' });
  });

  return app;
}
