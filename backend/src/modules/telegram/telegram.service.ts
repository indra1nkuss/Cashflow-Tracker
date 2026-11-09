import { Decimal } from '@prisma/client/runtime/library';
import { prisma } from '../../config/database.js';
import { telegramBotService } from '../../services/telegram-bot.service.js';
import { aiParserService } from '../ai-parser/ai-parser.service.js';
import { TelegramWebhookPayload } from './telegram.validation.js';
import { Logger } from '../../common/utils/logger.js';

interface LinkCodeData {
  userId: string;
  expiresAt: number;
}

export class TelegramService {
  // Temporary in-memory store for 6-digit pairing codes (valid 10 minutes)
  private static readonly linkCodes = new Map<string, LinkCodeData>();

  /**
   * Generates a 6-digit linking code for pairing mobile app with Telegram bot
   */
  public generateLinkCode(userId: string): { code: string; expiresAt: Date } {
    // Generate random 4-digit number e.g. PFT-7492
    const randomDigits = Math.floor(1000 + Math.random() * 9000).toString();
    const code = `PFT-${randomDigits}`;
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    TelegramService.linkCodes.set(code, {
      userId,
      expiresAt: expiresAt.getTime(),
    });

    Logger.info(`Generated Telegram link code ${code} for user ${userId}`);
    return { code, expiresAt };
  }

  /**
   * Process Telegram Webhook Updates
   * 1. Idempotency check with TelegramMessage table (chatId + messageId)
   * 2. Pairing / Account Linking (/start PFT-XXXX or /link PFT-XXXX)
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

    // 1. Idempotency check: prevent duplicate message processing
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

    // Save initial message record
    await prisma.telegramMessage.create({
      data: {
        chatId,
        messageId,
        rawText: text,
        status: 'PROCESSING',
      },
    });

    // 2. Check if this is an account pairing command: /link CODE or /start CODE
    const potentialCode = text.startsWith('/start ')
      ? text.replace('/start ', '').trim().toUpperCase()
      : text.startsWith('/link ')
          ? text.replace('/link ', '').trim().toUpperCase()
          : null;

    if (potentialCode && potentialCode.startsWith('PFT-')) {
      const codeData = TelegramService.linkCodes.get(potentialCode);

      if (!codeData || Date.now() > codeData.expiresAt) {
        await telegramBotService.sendMessage(
          msg.chat.id,
          '❌ <b>Kode tautan tidak valid atau sudah kedaluwarsa.</b>\n\nSilakan buat kode baru melalui menu <i>Pengaturan > Hubungkan Telegram</i> di aplikasi mobile Anda.'
        );
        await this.updateMessageStatus(chatId, messageId, 'LINK_CODE_EXPIRED');
        return;
      }

      // Link user
      const user = await prisma.user.findUnique({
        where: { id: codeData.userId },
      });

      if (!user) {
        await telegramBotService.sendMessage(msg.chat.id, '❌ User tidak ditemukan.');
        await this.updateMessageStatus(chatId, messageId, 'FAILED');
        return;
      }

      await prisma.telegramLink.upsert({
        where: { telegramUserId },
        create: {
          userId: user.id,
          telegramUserId,
          telegramChatId: chatId,
          telegramUsername: msg.from.username ?? null,
          firstName: msg.from.first_name ?? null,
          lastName: msg.from.last_name ?? null,
          isLinked: true,
        },
        update: {
          userId: user.id,
          telegramChatId: chatId,
          telegramUsername: msg.from.username ?? null,
          firstName: msg.from.first_name ?? null,
          lastName: msg.from.last_name ?? null,
          isLinked: true,
        },
      });

      // Remove consumed code
      TelegramService.linkCodes.delete(potentialCode);

      const welcomeMsg =
        `🎉 <b>Selamat, Akun Berhasil Ditautkan!</b>\n\n` +
        `Halo <b>${user.fullName}</b>, akun Telegram Anda kini terhubung dengan <b>Personal Finance Tracker</b>.\n\n` +
        `Sekarang Anda dapat mencatat keuangan dengan mengetik pesan biasa, contoh:\n` +
        `• <i>"Membeli bensin Rp50.000"</i>\n` +
        `• <i>"Makan siang 25rb"</i>\n` +
        `• <i>"Diterima gaji Rp5.000.000"</i>`;

      await telegramBotService.sendMessage(msg.chat.id, welcomeMsg);
      await this.updateMessageStatus(chatId, messageId, 'LINKED_SUCCESS');
      return;
    }

    // 3. Check link status
    const link = await prisma.telegramLink.findUnique({
      where: { telegramUserId },
      include: { user: true },
    });

    if (!link || !link.isLinked) {
      await telegramBotService.sendMessage(
        msg.chat.id,
        '⚠️ <b>Akun Telegram Anda belum ditautkan.</b>\n\n' +
        'Silakan buka aplikasi mobile <b>Personal Finance Tracker</b>, buka menu <i>Pengaturan > Hubungkan Telegram</i>, lalu kirimkan kode tautan ke sini.\n\n' +
        'Format: <code>/link PFT-XXXX</code>'
      );
      await this.updateMessageStatus(chatId, messageId, 'UNLINKED');
      return;
    }

    // Handle commands like /start or /help for already linked users
    if (text === '/start' || text === '/help') {
      await telegramBotService.sendMessage(
        msg.chat.id,
        `👋 Halo, <b>${link.user.fullName}</b>!\n\n` +
        `Kirimkan catatan pengeluaran atau pemasukan Anda secara langsung.\n` +
        `Contoh:\n` +
        `• <i>"Membeli bensin Rp50.000"</i>\n` +
        `• <i>"Makan siang di warteg 25rb"</i>\n` +
        `• <i>"Diterima gaji Rp5.000.000"</i>\n\n` +
        `Ketik <code>/status</code> untuk melihat akun yang terhubung.`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    if (text === '/status') {
      await telegramBotService.sendMessage(
        msg.chat.id,
        `ℹ️ <b>Status Akun</b>\n\n` +
        `Terhubung dengan: <b>${link.user.fullName}</b> (${link.user.email})`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    // 4. Parse message with AI parser
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

    const reply =
      `✅ <b>Transaksi Berhasil Dicatat!</b>\n\n` +
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
      where: { userId, isLinked: true },
    });

    return {
      isLinked: Boolean(link),
      telegramUsername: link?.telegramUsername || null,
      firstName: link?.firstName || null,
      linkedAt: link?.createdAt || null,
    };
  }

  public async unlink(userId: string): Promise<void> {
    await prisma.telegramLink.updateMany({
      where: { userId },
      data: { isLinked: false },
    });
  }
}

export const telegramService = new TelegramService();
