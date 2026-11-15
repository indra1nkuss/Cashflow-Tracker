import { env } from '../config/env.js';
import { Logger } from '../common/utils/logger.js';

export interface TelegramUpdate {
  update_id: number;
  message?: {
    message_id: number;
    from: {
      id: number;
      is_bot: boolean;
      first_name: string;
      last_name?: string;
      username?: string;
    };
    chat: {
      id: number;
      first_name?: string;
      type: string;
    };
    date: number;
    text?: string;
  };
}

export class TelegramBotService {
  private readonly botToken: string;
  private isPolling = false;
  private lastUpdateId = 0;

  constructor() {
    this.botToken = env.TELEGRAM_BOT_TOKEN;
    if (this.botToken && this.botToken.trim() !== '') {
      Logger.info('Telegram Bot service initialized with configured token.');
    } else {
      Logger.warn('TELEGRAM_BOT_TOKEN is not configured. TelegramBotService running in placeholder mode.');
    }
  }

  public isConfigured(): boolean {
    return Boolean(this.botToken && this.botToken.trim() !== '');
  }

  /**
   * Start long polling for local development when webhook is not active.
   */
  public async startPolling(handler: (update: any) => Promise<void>): Promise<void> {
    if (!this.isConfigured() || this.isPolling) return;
    this.isPolling = true;
    Logger.info('🤖 Telegram Bot long polling started for local development');

    const poll = async () => {
      while (this.isPolling) {
        try {
          const url = `https://api.telegram.org/bot${this.botToken}/getUpdates?offset=${this.lastUpdateId + 1}&timeout=15`;
          const res = await fetch(url);
          if (res.ok) {
            const data = (await res.json()) as { ok: boolean; result: any[] };
            if (data.ok && Array.isArray(data.result)) {
              for (const update of data.result) {
                this.lastUpdateId = update.update_id;
                try {
                  await handler(update);
                } catch (err) {
                  Logger.error('Error handling polled Telegram update:', err);
                }
              }
            }
          }
        } catch (error) {
          if (this.isPolling) {
            await new Promise((resolve) => setTimeout(resolve, 3000));
          }
        }
      }
    };

    void poll();
  }

  public stopPolling(): void {
    this.isPolling = false;
    Logger.info('Telegram Bot polling stopped');
  }

  /**
   * Send a response message back to a Telegram chat.
   */
  public async sendMessage(chatId: number | string, text: string): Promise<boolean> {
    if (!this.isConfigured()) {
      Logger.warn(`Telegram sendMessage called but bot token is not configured. ChatId: ${chatId}, Message: "${text}"`);
      return false;
    }

    try {
      const response = await fetch(`https://api.telegram.org/bot${this.botToken}/sendMessage`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          chat_id: chatId,
          text,
          parse_mode: 'HTML',
        }),
      });

      if (!response.ok) {
        const errorData = await response.text();
        Logger.error(`Telegram sendMessage failed: ${errorData}`);
        return false;
      }

      return true;
    } catch (error) {
      Logger.error('Failed to send Telegram message:', error);
      return false;
    }
  }
}

export const telegramBotService = new TelegramBotService();

