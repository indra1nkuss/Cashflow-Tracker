import { Request, Response, NextFunction } from 'express';
import { AppError } from '../errors/app-error.js';
import { ApiResponse } from '../utils/api-response.js';
import { Logger } from '../utils/logger.js';
import { env } from '../../config/env.js';

export const errorHandler = (
  err: Error,
  _req: Request,
  res: Response,
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  _next: NextFunction
): void => {
  if (err instanceof AppError) {
    ApiResponse.error(res, err.message, err.statusCode, err.details);
    return;
  }

  // Unhandled / system errors
  Logger.error(`Unhandled error: ${err.message}`, err.stack);

  const message =
    env.NODE_ENV === 'production' ? 'Internal server error occurred' : err.message;

  ApiResponse.error(
    res,
    message,
    500,
    env.NODE_ENV === 'development' ? { stack: err.stack } : undefined
  );
};

