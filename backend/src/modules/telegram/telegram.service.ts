import { Decimal } from '@prisma/client/runtime/library';
import { prisma } from '../../config/database.js';
import { telegramBotService } from '../../services/telegram-bot.service.js';
import { aiParserService } from '../ai-parser/ai-parser.service.js';
import { TelegramWebhookPayload } from './telegram.validation.js';
import { Logger } from '../../common/utils/logger.js';

export class TelegramService {
  /**
   * Process Telegram Webhook Updates
   * 1. Idempotency check with TelegramMessage table (chatId + messageId)
   * 2. Check if sender is linked to a user in TelegramLink
   * 3. AI Transaction parsing
   * 4. Save transaction or ask for clarification
   */
  public async handleWebhookUpdate(payload: TelegramWebhookPayload): Promise<void> {
    const msg = payload.message;
    if (!msg || !msg.text) {
      return;
    }

    const chatId = BigInt(msg.chat.id);
    const messageId = BigInt(msg.message_id);
    const telegramUserId = BigInt(msg.from.id);
    const text = msg.text.trim();

    // Idempotency check: prevent duplicate message processing
    const existingMessage = await prisma.telegramMessage.findUnique({
      where: {
        chatId_messageId: {
          chatId,
          messageId,
        },
      },
    });

    if (existingMessage) {
      Logger.warn(`Duplicate Telegram message received and ignored: chat=${chatId}, message=${messageId}`);
      return;
    }

    // Save message record
    await prisma.telegramMessage.create({
      data: {
        chatId,
        messageId,
        rawText: text,
        status: 'PROCESSING',
      },
    });

    // Check link status
    const link = await prisma.telegramLink.findUnique({
      where: { telegramUserId },
      include: { user: true },
    });

    if (!link || !link.isLinked) {
      await telegramBotService.sendMessage(
        msg.chat.id,
        '⚠️ Akun Telegram Anda belum ditautkan dengan Personal Finance Tracker.\n\nSilakan tautkan akun Anda melalui aplikasi mobile untuk mulai mencatat keuangan.'
      );
      await this.updateMessageStatus(chatId, messageId, 'UNLINKED');
      return;
    }

    // Handle commands like /start or /help
    if (text.startsWith('/')) {
      await telegramBotService.sendMessage(
        msg.chat.id,
        `👋 Halo, <b>${link.user.fullName}</b>!\n\nKirimkan catatan pengeluaran atau pemasukan Anda secara langsung.\nContoh:\n- <i>"Membeli bensin Rp50.000"</i>\n- <i>"Diterima gaji Rp5.000.000"</i>`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    // Parse message with AI parser
    const parsed = await aiParserService.parseTransactionMessage(text, link.userId);

    // If missing nominal or needs clarification
    if (parsed.needsClarification || !parsed.amount || !parsed.type) {
      const clarifyText =
        parsed.clarificationMessage ||
        '⚠️ Maaf, informasi transaksi belum lengkap (nominal wajib dicantumkan). Contoh: "Membeli bensin Rp50.000".';
      await telegramBotService.sendMessage(msg.chat.id, clarifyText);
      await this.updateMessageStatus(chatId, messageId, 'NEED_CLARIFICATION');
      return;
    }

    // Find default or first account for the user
    let account = await prisma.account.findFirst({
      where: { userId: link.userId, isArchived: false },
    });

    if (!account) {
      account = await prisma.account.create({
        data: {
          userId: link.userId,
          name: 'Dompet Utama',
          initialBalance: new Decimal(0),
        },
      });
    }

    // Find or create category
    const categoryName = parsed.category || (parsed.type === 'INCOME' ? 'Pemasukan Lainnya' : 'Pengeluaran Lainnya');
    let category = await prisma.category.findFirst({
      where: {
        name: { equals: categoryName, mode: 'insensitive' },
        OR: [{ userId: link.userId }, { isDefault: true }],
      },
    });

    if (!category) {
      category = await prisma.category.create({
        data: {
          userId: link.userId,
          name: categoryName,
          type: parsed.type,
        },
      });
    }

    // Save transaction
    const transaction = await prisma.transaction.create({
      data: {
        userId: link.userId,
        accountId: account.id,
        categoryId: category.id,
        type: parsed.type,
        amount: new Decimal(parsed.amount),
        description: parsed.description || text,
        transactionDate: new Date(),
        source: 'TELEGRAM_BOT',
      },
    });

    const formattedAmount = new Intl.NumberFormat('id-ID', {
      style: 'currency',
      currency: 'IDR',
      maximumFractionDigits: 0,
    }).format(Number(transaction.amount));

    const reply = `✅ <b>Transaksi Berhasil Dicatat!</b>\n\n` +
      `<b>Jenis:</b> ${transaction.type === 'INCOME' ? '📈 Pemasukan' : '📉 Pengeluaran'}\n` +
      `<b>Nominal:</b> ${formattedAmount}\n` +
      `<b>Kategori:</b> ${category.name}\n` +
      `<b>Deskripsi:</b> ${transaction.description}\n` +
      `<b>Akun:</b> ${account.name}`;

    await telegramBotService.sendMessage(msg.chat.id, reply);
    await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
  }

  private async updateMessageStatus(chatId: bigint, messageId: bigint, status: string): Promise<void> {
    try {
      await prisma.telegramMessage.update({
        where: { chatId_messageId: { chatId, messageId } },
        data: { status },
      });
    } catch (err) {
      Logger.warn('Failed to update telegram message status:', err);
    }
  }

  public async getLinkStatus(userId: string) {
    const link = await prisma.telegramLink.findFirst({
      where: { userId },
    });

    return {
      isLinked: Boolean(link?.isLinked),
      telegramUsername: link?.telegramUsername || null,
      linkedAt: link?.createdAt || null,
    };
  }
}

export const telegramService = new TelegramService();

