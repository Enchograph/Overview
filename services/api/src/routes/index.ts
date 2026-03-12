import { Router, type Router as ExpressRouter } from 'express';

import type { AiService } from '../ai/types.js';
import { createRequireAuth } from '../auth/middleware.js';
import type { AuthRepository } from '../auth/types.js';
import type { PlanningRepository } from '../planning/types.js';
import { createAiRouter } from './ai.js';
import { createAuthRouter } from './auth.js';
import { healthRouter } from './health.js';
import { createPlanningRouter } from './planning.js';

export function createApiRouter(
  aiService: AiService,
  authRepository: AuthRepository,
  planningRepository: PlanningRepository,
): ExpressRouter {
  const apiRouter: ExpressRouter = Router();

  apiRouter.use('/health', healthRouter);
  apiRouter.use('/auth', createAuthRouter(authRepository));
  apiRouter.use(
    '/planning',
    createRequireAuth(authRepository),
    createPlanningRouter(planningRepository),
  );
  apiRouter.use(
    '/ai',
    createRequireAuth(authRepository),
    createAiRouter(aiService),
  );

  return apiRouter;
}
