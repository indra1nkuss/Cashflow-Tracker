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

