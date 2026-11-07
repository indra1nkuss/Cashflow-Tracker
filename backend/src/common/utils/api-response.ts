import { Response } from 'express';

export interface ApiResponseOptions<T = unknown> {
  success: boolean;
  message: string;
  data?: T;
  errors?: unknown;
  meta?: Record<string, unknown>;
}

export class ApiResponse {
  public static success<T>(
    res: Response,
    data?: T,
    message = 'Success',
    statusCode = 200,
    meta?: Record<string, unknown>
  ): Response {
    const payload: ApiResponseOptions<T> = {
      success: true,
      message,
      data,
      ...(meta ? { meta } : {}),
    };
    return res.status(statusCode).json(payload);
  }

  public static created<T>(
    res: Response,
    data?: T,
    message = 'Resource created successfully'
  ): Response {
    return this.success(res, data, message, 201);
  }

  public static error(
    res: Response,
    message = 'Internal Server Error',
    statusCode = 500,
    errors?: unknown
  ): Response {
    const payload: ApiResponseOptions = {
      success: false,
      message,
      ...(errors ? { errors } : {}),
    };
    return res.status(statusCode).json(payload);
  }
}

