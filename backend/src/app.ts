import express, { Application } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { env } from './config/env.js';
import { apiRouter } from './routes/index.js';
import { errorHandler } from './common/middleware/error-handler.middleware.js';
import { notFoundHandler } from './common/middleware/not-found.middleware.js';
import { generalRateLimiter } from './common/middleware/rate-limiter.middleware.js';
import { telegramController } from './modules/telegram/telegram.controller.js';

export const createApp = (): Application => {
  const app = express();

  // Enable 'trust proxy' for cloud reverse proxies (Render, Cloudflare, Fly, Koyeb)
  app.set('trust proxy', 1);

  // Disable ETag to ensure real-time financial data is never cached with 304
  app.set('etag', false);

  // ───────── Security & Parsing ─────────
  app.use(helmet());
  app.use(
    cors({
      origin: (origin, callback) => {
        // Allow requests with no origin (mobile apps, Postman, curl, Telegram)
        if (!origin) return callback(null, true);
        
        const allowedOrigins = process.env['ALLOWED_ORIGINS']
          ? process.env['ALLOWED_ORIGINS'].split(',').map((o) => o.trim())
          : ['*'];

        if (
          allowedOrigins.includes('*') ||
          allowedOrigins.includes(origin) ||
          origin.endsWith('.vercel.app') ||
          origin.includes('localhost')
        ) {
          return callback(null, true);
        }

        return callback(null, true);
      },
      credentials: true,
    })
  );
  app.use(express.json({ limit: '5mb' }));
  app.use(express.urlencoded({ extended: true }));

  // ───────── HTTP Logging ─────────
  if (env.NODE_ENV !== 'test') {
    app.use(morgan(env.NODE_ENV === 'production' ? 'combined' : 'dev'));
  }

  // ───────── Root Landing (Browser Friendly) ─────────
  app.get('/', (_req, res) => {
    res.status(200).json({
      success: true,
      message: 'Personal Finance Tracker API is online and running on Vercel!',
      endpoints: {
        health: '/api/health',
        api: '/api',
      },
      version: '1.0.0',
    });
  });

  // ───────── Health Check (Exempt from rate limits for monitoring) ─────────
  app.get('/api/health', (_req, res) => {
    res.status(200).json({
      success: true,
      message: 'Personal Finance Tracker API is running',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
    });
  });

  // ───────── Telegram Webhook (Exempt from rate limits) ─────────
  app.post('/api/telegram/webhook', (req, res, next) => {
    telegramController.handleWebhook(req, res, next);
  });

  // ───────── Anti-Cache Middleware for Real-time Financial Data ─────────
  app.use('/api', (_req, res, next) => {
    res.setHeader('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0');
    res.setHeader('Pragma', 'no-cache');
    res.setHeader('Expires', '0');
    res.setHeader('Surrogate-Control', 'no-store');
    next();
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

