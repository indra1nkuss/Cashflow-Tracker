import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { apiRouter } from './routes/index.js';
import { errorHandler } from './common/middleware/error-handler.middleware.js';
import { notFoundHandler } from './common/middleware/not-found.middleware.js';

export const createApp = (): Application => {
  const app = express();

  // ───────── Security & Parsing ─────────
  app.use(helmet());
  app.use(
    cors({
      origin:
        env.NODE_ENV === 'production'
          ? process.env['ALLOWED_ORIGINS']?.split(',') ?? []
          : '*',
      credentials: true,
    })
  );
  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true }));

  // ───────── HTTP Logging ─────────
  if (env.NODE_ENV !== 'test') {
    app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
  }

  // ───────── API Routes ─────────
  app.use('/api', apiRouter);

  // ───────── 404 & Error Handlers ─────────
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};

