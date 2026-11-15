import { createApp } from './app.js';
import { env } from './config/env.js';
import { prisma } from './config/database.js';
import { Logger } from './common/utils/logger.js';
import { telegramBotService } from './services/telegram-bot.service.js';

const app = createApp();

const startServer = async (): Promise<void> => {
  try {
    // Test database connection
    await prisma.$connect();
    Logger.info('✅ Database connection established (Supabase PostgreSQL)');

    app.listen(env.PORT, '0.0.0.0', () => {
      Logger.info(`🚀 Server is running in ${env.NODE_ENV} mode`);
      Logger.info(`📡 Listening on http://0.0.0.0:${env.PORT}`);
      Logger.info(`🏥 Health check: http://localhost:${env.PORT}/api/health`);
    });

    // In local development mode without registered webhook, start long polling automatically
    if (env.NODE_ENV === 'development' && telegramBotService.isConfigured()) {
      try {
        const webhookInfoRes = await fetch(
          `https://api.telegram.org/bot${env.TELEGRAM_BOT_TOKEN}/getWebhookInfo`
        );
        const webhookInfo = (await webhookInfoRes.json()) as {
          ok: boolean;
          result?: { url?: string };
        };
        if (webhookInfo.ok && (!webhookInfo.result?.url || webhookInfo.result.url === '')) {
          const { telegramService } = await import(
            './modules/telegram/telegram.service.js'
          );
          void telegramBotService.startPolling((update) =>
            telegramService.handleWebhookUpdate(update)
          );
        }
      } catch (err) {
        Logger.warn('Could not initialize Telegram long polling:', err);
      }
    }
  } catch (error) {
    Logger.error('❌ Failed to start server:', error);
    process.exit(1);
  }
};

// Graceful shutdown
const shutdown = async (signal: string): Promise<void> => {
  Logger.info(`${signal} received. Shutting down gracefully...`);
  telegramBotService.stopPolling();
  await prisma.$disconnect();
  Logger.info('Database connection closed.');
  process.exit(0);
};

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

void startServer();

