import type { NextFunction, Request, Response } from 'express';

import { HttpError, toErrorResponse } from '../planning/errors.js';
import type { AuthRepository, AuthUser } from './types.js';

export type AuthenticatedRequest = Request & { authUser: AuthUser };

export function createRequireAuth(authRepository: AuthRepository) {
  return async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const header = req.header('authorization');
      const token = _parseBearerToken(header);
      if (!token) {
        throw new HttpError(401, 'Authorization required');
      }

      const user = await authRepository.getUserForToken(token);
      if (!user) {
        throw new HttpError(401, 'Invalid or expired session');
      }

      (req as AuthenticatedRequest).authUser = user;
      next();
    } catch (error) {
      const response = toErrorResponse(error);
      res.status(response.statusCode).json(response.payload);
    }
  };
}

function _parseBearerToken(header: string | undefined): string | null {
  if (!header) {
    return null;
  }

  const [scheme, token] = header.split(' ');
  if (scheme?.toLowerCase() != 'bearer' || !token) {
    return null;
  }

  return token;
}
