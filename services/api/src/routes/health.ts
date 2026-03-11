import { Router, type Router as ExpressRouter } from 'express';

import { createHealthResponse } from '@overview/shared';

export const healthRouter: ExpressRouter = Router();

healthRouter.get('/', (_req, res) => {
  res.json(createHealthResponse());
});
