import { Router, type Response } from 'express';

import { toErrorResponse } from '../planning/errors.js';
import { loginSchema, registerSchema } from '../auth/schemas.js';
import type { AuthRepository } from '../auth/types.js';

async function handleRequest(
  res: Response,
  action: () => Promise<void>,
): Promise<void> {
  try {
    await action();
  } catch (error) {
    const response = toErrorResponse(error);
    res.status(response.statusCode).json(response.payload);
  }
}

export function createAuthRouter(repository: AuthRepository): Router {
  const router = Router();

  router.post('/register', (req, res) =>
    handleRequest(res, async () => {
      const input = registerSchema.parse(req.body);
      const session = await repository.register(input);
      res.status(201).json(session);
    }),
  );

  router.post('/login', (req, res) =>
    handleRequest(res, async () => {
      const input = loginSchema.parse(req.body);
      const session = await repository.login(input);
      res.json(session);
    }),
  );

  return router;
}
