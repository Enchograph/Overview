import { Router, type Request, type Response } from 'express';

import { AiErrorCodes } from '../ai/error-codes.js';
import {
  ingestTextSchema,
  askQuestionSchema,
  transcribeAudioSchema,
} from '../ai/schemas.js';
import type { AiService } from '../ai/types.js';
import { HttpError, toErrorResponse } from '../planning/errors.js';
import type { AuthenticatedRequest } from '../auth/middleware.js';

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

export function createAiRouter(service: AiService): Router {
  const router = Router();

  router.post('/ingest/text', (req, res) =>
    handleRequest(res, async () => {
      const input = ingestTextSchema.parse(req.body);
      const result = await service.ingestText(_userId(req), input.text);
      res.json(result);
    }),
  );

  router.post('/ask', (req, res) =>
    handleRequest(res, async () => {
      const input = askQuestionSchema.parse(req.body);
      const result = await service.answerQuestion(_userId(req), input.question);
      res.json(result);
    }),
  );

  router.post('/transcribe', (req, res) =>
    handleRequest(res, async () => {
      const input = transcribeAudioSchema.parse(req.body);
      const result = await service.transcribeAudio(_userId(req), input);
      res.json(result);
    }),
  );

  return router;
}

function _userId(request: Request): string {
  if (!_isAuthenticatedRequest(request)) {
    throw new HttpError(
      401,
      'Authorization required',
      AiErrorCodes.authorizationRequired,
    );
  }

  return request.authUser.id;
}

function _isAuthenticatedRequest(
  request: Request,
): request is AuthenticatedRequest {
  const authUser = (request as { authUser?: unknown }).authUser;

  return (
    typeof authUser === 'object' &&
    authUser !== null &&
    'id' in authUser &&
    typeof authUser.id === 'string'
  );
}
