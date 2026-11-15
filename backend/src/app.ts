import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { apiRouter } from './routes/index.js';
import { errorHandler } from './common/middleware/error-handler.middleware.js';
import { notFoundHandler } from './common/middleware/not-found.middleware.js';
import { generalRateLimiter } from './common/middleware/rate-limiter.middleware.js';

export const createApp = (): Application => {
  const app = express();

  // Enable 'trust proxy' for cloud reverse proxies (Render, Cloudflare, Fly, Koyeb)
  app.set('trust proxy', 1);

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

  // ───────── Health Check (Exempt from rate limits for monitoring) ─────────
  app.get('/api/health', (_req, res) => {
    res.status(200).json({
      success: true,
      message: 'Personal Finance Tracker API is running',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    });
  });

  // ───────── Global Rate Limiter ─────────
  app.use('/api', generalRateLimiter);

  // ───────── API Routes ─────────
  app.use('/api', apiRouter);

  // ───────── 404 & Error Handlers ─────────
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
};

