import { Router, type Router as ExpressRouter } from 'express';

import type { AuthRepository } from '../auth/types.js';
import type { PlanningRepository } from '../planning/types.js';
import { createAuthRouter } from './auth.js';
import { healthRouter } from './health.js';
import { createPlanningRouter } from './planning.js';

export function createApiRouter(
  authRepository: AuthRepository,
  planningRepository: PlanningRepository,
): ExpressRouter {
  const apiRouter: ExpressRouter = Router();

  apiRouter.use('/health', healthRouter);
  apiRouter.use('/auth', createAuthRouter(authRepository));
  apiRouter.use('/planning', createPlanningRouter(planningRepository));

  return apiRouter;
}
