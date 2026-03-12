import { Router, type Request, type Response } from 'express';

import type { AuthenticatedRequest } from '../auth/middleware.js';
import { HttpError, toErrorResponse } from '../planning/errors.js';
import {
  createMemoSchema,
  createScheduleSchema,
  createTaskSchema,
  idParamSchema,
  updateMemoSchema,
  updateScheduleSchema,
  updateTaskSchema,
} from '../planning/schemas.js';
import type { PlanningRepository } from '../planning/types.js';

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

async function requireById<T>(
  value: Promise<T | null>,
  missingMessage: string,
): Promise<T> {
  const item = await value;

  if (!item) {
    throw new HttpError(404, missingMessage);
  }

  return item;
}

export function createPlanningRouter(repository: PlanningRepository): Router {
  const router = Router();

  router.get('/schedules', (req, res) =>
    handleRequest(res, async () => {
      res.json({ items: await repository.listSchedules(_userId(req)) });
    }),
  );

  router.get('/schedules/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const item = await requireById(
        repository.getSchedule(params.id, _userId(req)),
        'Schedule not found',
      );
      res.json(item);
    }),
  );

  router.post('/schedules', (req, res) =>
    handleRequest(res, async () => {
      const input = createScheduleSchema.parse(req.body);
      const item = await repository.createSchedule(input, _userId(req));
      res.status(201).json(item);
    }),
  );

  router.patch('/schedules/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const input = updateScheduleSchema.parse(req.body);
      const item = await requireById(
        repository.updateSchedule(params.id, input, _userId(req)),
        'Schedule not found',
      );
      res.json(item);
    }),
  );

  router.delete('/schedules/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const deleted = await repository.deleteSchedule(params.id, _userId(req));

      if (!deleted) {
        throw new HttpError(404, 'Schedule not found');
      }

      res.status(204).send();
    }),
  );

  router.get('/tasks', (req, res) =>
    handleRequest(res, async () => {
      res.json({ items: await repository.listTasks(_userId(req)) });
    }),
  );

  router.get('/tasks/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const item = await requireById(
        repository.getTask(params.id, _userId(req)),
        'Task not found',
      );
      res.json(item);
    }),
  );

  router.post('/tasks', (req, res) =>
    handleRequest(res, async () => {
      const input = createTaskSchema.parse(req.body);
      const item = await repository.createTask(input, _userId(req));
      res.status(201).json(item);
    }),
  );

  router.patch('/tasks/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const input = updateTaskSchema.parse(req.body);
      const item = await requireById(
        repository.updateTask(params.id, input, _userId(req)),
        'Task not found',
      );
      res.json(item);
    }),
  );

  router.delete('/tasks/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const deleted = await repository.deleteTask(params.id, _userId(req));

      if (!deleted) {
        throw new HttpError(404, 'Task not found');
      }

      res.status(204).send();
    }),
  );

  router.get('/memos', (req, res) =>
    handleRequest(res, async () => {
      res.json({ items: await repository.listMemos(_userId(req)) });
    }),
  );

  router.get('/memos/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const item = await requireById(
        repository.getMemo(params.id, _userId(req)),
        'Memo not found',
      );
      res.json(item);
    }),
  );

  router.post('/memos', (req, res) =>
    handleRequest(res, async () => {
      const input = createMemoSchema.parse(req.body);
      const item = await repository.createMemo(input, _userId(req));
      res.status(201).json(item);
    }),
  );

  router.patch('/memos/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const input = updateMemoSchema.parse(req.body);
      const item = await requireById(
        repository.updateMemo(params.id, input, _userId(req)),
        'Memo not found',
      );
      res.json(item);
    }),
  );

  router.delete('/memos/:id', (req, res) =>
    handleRequest(res, async () => {
      const params = idParamSchema.parse(req.params);
      const deleted = await repository.deleteMemo(params.id, _userId(req));

      if (!deleted) {
        throw new HttpError(404, 'Memo not found');
      }

      res.status(204).send();
    }),
  );

  return router;
}

function _userId(request: Request): string {
  if (!_isAuthenticatedRequest(request)) {
    throw new HttpError(401, 'Authorization required');
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
