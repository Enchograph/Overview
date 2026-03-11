import { Router, type Router as ExpressRouter } from 'express';

import type { PlanningRepository } from '../planning/types.js';
import { healthRouter } from './health.js';
import { createPlanningRouter } from './planning.js';

export function createApiRouter(repository: PlanningRepository): ExpressRouter {
  const apiRouter: ExpressRouter = Router();

  apiRouter.use('/health', healthRouter);
  apiRouter.use('/planning', createPlanningRouter(repository));

  return apiRouter;
}
