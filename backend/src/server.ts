import { createApp } from './app.js';
import { env } from './config/env.js';
import { prisma } from './config/database.js';
import { Logger } from './common/utils/logger.js';

const app = createApp();

const startServer = async (): Promise<void> => {
  try {
    // Test database connection
    await prisma.$connect();
    Logger.info('✅ Database connection established (Supabase PostgreSQL)');

    app.listen(env.PORT, () => {
      Logger.info(`🚀 Server is running in ${env.NODE_ENV} mode`);
      Logger.info(`📡 Listening on http://localhost:${env.PORT}`);
      Logger.info(`🏥 Health check: http://localhost:${env.PORT}/api/health`);
    });
  } catch (error) {
    Logger.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async (signal: string): Promise<void> => {
  Logger.info(`${signal} received. Shutting down gracefully...`);
  await prisma.$disconnect();
  Logger.info('Database connection closed.');
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

void startServer();

