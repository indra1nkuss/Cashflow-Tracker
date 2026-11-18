import { Decimal } from '@prisma/client/runtime/library';
import { prisma } from '../../config/database.js';
import { telegramBotService } from '../../services/telegram-bot.service.js';
import { aiParserService } from '../ai-parser/ai-parser.service.js';
import { reportsService, ReportPeriod, ReportSummaryResult } from '../reports/reports.service.js';
import { TelegramWebhookPayload } from './telegram.validation.js';
import { Logger } from '../../common/utils/logger.js';

export class TelegramService {
  /**
   * Generates a linking code for pairing mobile app with Telegram bot.
   * Code is stored in Supabase DB (not in-memory) so it works in serverless.
   */
  public async generateLinkCode(userId: string): Promise<{ code: string; expiresAt: Date }> {
    // Generate random 4-digit number e.g. PFT-7492
    const randomDigits = Math.floor(1000 + Math.random() * 9000).toString();
    const code = `PFT-${randomDigits}`;
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Delete any existing unused codes for this user first (cleanup)
    await prisma.telegramLinkCode.deleteMany({ where: { userId } });

    // Save the new code to database
    await prisma.telegramLinkCode.create({
      data: { code, userId, expiresAt },
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
      // Look up code from database (works in serverless - no in-memory state)
      const codeData = await prisma.telegramLinkCode.findUnique({
        where: { code: potentialCode },
      });

      if (!codeData || new Date() > codeData.expiresAt) {
        // Cleanup expired code if it exists
        if (codeData) await prisma.telegramLinkCode.delete({ where: { code: potentialCode } });

        await telegramBotService.sendMessage(
          msg.chat.id,
          'âŒ <b>Kode tautan tidak valid atau sudah kedaluwarsa.</b>\n\nSilakan buat kode baru melalui menu <i>Pengaturan > Hubungkan Telegram</i> di aplikasi mobile Anda.'
        );
        await this.updateMessageStatus(chatId, messageId, 'LINK_CODE_EXPIRED');
        return;
      }

      // Link user
      const user = await prisma.user.findUnique({
        where: { id: codeData.userId },
      });

      if (!user) {
        await telegramBotService.sendMessage(msg.chat.id, 'âŒ User tidak ditemukan.');
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

      // Delete consumed code from database
      await prisma.telegramLinkCode.delete({ where: { code: potentialCode } });

      const welcomeMsg =
        `ðŸŽ‰ <b>Selamat, Akun Berhasil Ditautkan!</b>\n\n` +
        `Halo <b>${user.fullName}</b>, akun Telegram Anda kini terhubung dengan <b>Personal Finance Tracker</b>.\n\n` +
        `Sekarang Anda dapat mencatat keuangan dengan mengetik pesan biasa, contoh:\n` +
        `â€¢ <i>"Membeli bensin Rp50.000"</i>\n` +
        `â€¢ <i>"Makan siang 25rb"</i>\n` +
        `â€¢ <i>"Diterima gaji Rp5.000.000"</i>`;

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
        'âš ï¸ <b>Akun Telegram Anda belum ditautkan.</b>\n\n' +
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
        `ðŸ‘‹ Halo, <b>${link.user.fullName}</b>!\n\n` +
        `Kirimkan catatan pengeluaran atau pemasukan Anda secara langsung.\n` +
        `Contoh:\n` +
        `â€¢ <i>"Membeli bensin Rp50.000"</i>\n` +
        `â€¢ <i>"Makan siang di warteg 25rb"</i>\n` +
        `â€¢ <i>"Diterima gaji Rp5.000.000"</i>\n\n` +
        `Perintah bantuan:\n` +
        `â€¢ <code>/laporan</code> - Laporan keuangan bulan ini\n` +
        `â€¢ <code>/laporan hari</code> - Laporan keuangan hari ini\n` +
        `â€¢ <code>/laporan minggu</code> - Laporan keuangan minggu ini\n` +
        `â€¢ <code>/laporan tahun</code> - Laporan keuangan tahun ini\n` +
        `â€¢ <code>/batal</code> - Membatalkan transaksi terakhir jika salah catat\n` +
        `â€¢ <code>/status</code> - Melihat akun yang sedang terhubung`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    if (text === '/status') {
      await telegramBotService.sendMessage(
        msg.chat.id,
        `â„¹ï¸ <b>Status Akun</b>\n\n` +
        `Terhubung dengan: <b>${link.user.fullName}</b> (${link.user.email})`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    if (text === '/batal' || text === '/undo') {
      const lastTx = await prisma.transaction.findFirst({
        where: { userId: link.userId, source: 'TELEGRAM_BOT' },
        orderBy: { createdAt: 'desc' },
      });

      if (!lastTx) {
        await telegramBotService.sendMessage(
          msg.chat.id,
          'â„¹ï¸ Tidak ada transaksi via Telegram yang dapat dibatalkan saat ini.'
        );
        await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
        return;
      }

      await prisma.transaction.delete({
        where: { id: lastTx.id },
      });

      const formattedAmount = new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
      }).format(Number(lastTx.amount));

      await telegramBotService.sendMessage(
        msg.chat.id,
        `ðŸ—‘ï¸ <b>Transaksi Terakhir Dibatalkan!</b>\n\n` +
        `â€¢ <b>Keterangan:</b> ${lastTx.description}\n` +
        `â€¢ <b>Nominal:</b> ${formattedAmount}\n\n` +
        `Transaksi telah dihapus dari pencatatan keuangan Anda.`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    // 4. Handle Report commands: /laporan, /rekap, /report, etc.
    const lowerText = text.toLowerCase().trim();
    const isReportCommand =
      lowerText.startsWith('/laporan') ||
      lowerText.startsWith('/rekap') ||
      lowerText.startsWith('/report') ||
      lowerText === 'laporan' ||
      lowerText === 'rekap';

    if (isReportCommand) {
      let period: ReportPeriod = 'month';

      if (
        lowerText.includes('hari') ||
        lowerText.includes('today') ||
        lowerText === '/laporanhari'
      ) {
        period = 'day';
      } else if (
        lowerText.includes('minggu') ||
        lowerText.includes('week') ||
        lowerText === '/laporanminggu'
      ) {
        period = 'week';
      } else if (
        lowerText.includes('tahun') ||
        lowerText.includes('year') ||
        lowerText === '/laporantahun'
      ) {
        period = 'year';
      } else if (
        lowerText.includes('bulan') ||
        lowerText.includes('month') ||
        lowerText === '/laporanbulan'
      ) {
        period = 'month';
      }

      const report = await reportsService.getPeriodSummary(link.userId, period);
      const reportMessage = this.formatReportMessage(report, link.user.fullName);

      await telegramBotService.sendMessage(msg.chat.id, reportMessage);
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    // 5. Parse message with AI parser
    const parsed = await aiParserService.parseTransactionMessage(text, link.userId);

    // If missing nominal or needs clarification
    if (parsed.needsClarification || !parsed.amount || !parsed.type) {
      const clarifyText =
        parsed.clarificationMessage ||
        'âš ï¸ Maaf, informasi transaksi belum lengkap (nominal wajib dicantumkan). Contoh: "Membeli bensin Rp50.000".';
      await telegramBotService.sendMessage(msg.chat.id, clarifyText);
      await this.updateMessageStatus(chatId, messageId, 'NEED_CLARIFICATION');
      return;
    }

    // Smart account routing berdasarkan nama yang disebutkan di pesan
    const mentionedAccount = (parsed.accountName ?? '').trim() || null;

    // Helper: deteksi tipe akun dari nama
    const detectAccountType = (name: string): string => {
      const n = name.toLowerCase();
      if (['bca', 'bni', 'mandiri', 'bri', 'btn', 'cimb', 'danamon', 'permata', 'maybank', 'ocbc', 'bsi'].some(k => n.includes(k))) return 'BANK';
      if (['gopay', 'ovo', 'dana', 'shopeepay', 'linkaja', 'sakuku', 'isaku', 'jenius', 'blu'].some(k => n.includes(k))) return 'EWALLET';
      if (['reksadana', 'reksa', 'saham', 'investasi', 'bibit', 'bareksa', 'ajaib', 'stockbit'].some(k => n.includes(k))) return 'INVESTMENT';
      if (['cash', 'tunai', 'dompet'].some(k => n.includes(k))) return 'CASH';
      return 'OTHER';
    };

    let account;

    if (mentionedAccount) {
      // Cari akun berdasarkan nama (case-insensitive contains)
      account = await prisma.account.findFirst({
        where: {
          userId: link.userId,
          isArchived: false,
          name: { contains: mentionedAccount, mode: 'insensitive' },
        },
      });

      if (!account) {
        // Auto-buat akun baru dengan nama yang disebutkan
        const detectedType = detectAccountType(mentionedAccount);
        account = await prisma.account.create({
          data: {
            userId: link.userId,
            name: mentionedAccount,
            accountType: detectedType as any,
            initialBalance: new Decimal(0),
          },
        });
        Logger.info(`Auto-created account: ` + mentionedAccount + ` (` + detectedType + `) for user ` + link.userId);
      }
    } else {
      // Tidak ada nama akun disebutkan -> tanya user
      const clarifyText =
        parsed.type === 'INCOME'
          ? 'Diterima ke akun mana?\nContoh: "diterima gaji BNI 5jt" atau "terima transferan GoPay 200rb"'
          : 'Dibayar dari akun mana?\nContoh: "beli bensin GoPay 50rb" atau "bayar listrik BCA 150rb"';

      await telegramBotService.sendMessage(msg.chat.id, clarifyText);
      await this.updateMessageStatus(chatId, messageId, 'NEED_CLARIFICATION');
      return;
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
      `âœ… <b>Transaksi Berhasil Dicatat!</b>\n\n` +
      `<b>Jenis:</b> ${transaction.type === 'INCOME' ? 'ðŸ“ˆ Pemasukan' : 'ðŸ“‰ Pengeluaran'}\n` +
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

  private formatReportMessage(report: ReportSummaryResult, userName: string): string {
    const fmt = (num: number) =>
      new Intl.NumberFormat('id-ID', {
        style: 'currency',
        currency: 'IDR',
        maximumFractionDigits: 0,
      }).format(num);

    const netSign = report.netCashflow > 0 ? '+' : '';
    const netEmoji = report.netCashflow >= 0 ? 'ðŸ“ˆ' : 'ðŸ“‰';

    let msg = `ðŸ“Š <b>LAPORAN KEUANGAN</b>\n`;
    msg += `ðŸ—“ï¸ <b>Periode:</b> ${report.periodLabel}\n`;
    msg += `ðŸ‘¤ <b>Pengguna:</b> ${userName}\n`;
    msg += `â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€\n`;
    msg += `ðŸ’° <b>Pemasukan:</b>  ${fmt(report.totalIncome)}\n`;
    msg += `ðŸ’¸ <b>Pengeluaran:</b> ${fmt(report.totalExpense)}\n`;
    msg += `${netEmoji} <b>Selisih (Net):</b> ${netSign}${fmt(report.netCashflow)}\n`;
    msg += `ðŸ“ <b>Total Transaksi:</b> ${report.transactionCount} catatan\n`;
    msg += `â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€\n`;

    if (report.expenseCategories.length > 0) {
      msg += `\nðŸ”´ <b>Rincian Pengeluaran:</b>\n`;
      for (const cat of report.expenseCategories) {
        const pct =
          report.totalExpense > 0
            ? ((cat.total / report.totalExpense) * 100).toFixed(0)
            : '0';
        msg += `â€¢ ${cat.name}: <b>${fmt(cat.total)}</b> (${pct}%)\n`;
      }
    }

    if (report.incomeCategories.length > 0) {
      msg += `\nðŸŸ¢ <b>Rincian Pemasukan:</b>\n`;
      for (const cat of report.incomeCategories) {
        msg += `â€¢ ${cat.name}: <b>${fmt(cat.total)}</b>\n`;
      }
    }

    if (report.transactionCount === 0) {
      msg += `\n<i>Belum ada transaksi tercatat pada periode ini.</i>\n`;
    }

    msg += `\nðŸ’¡ <i>Pilihan perintah laporan:</i>\n`;
    msg += `â€¢ <code>/laporan hari</code> (Hari Ini)\n`;
    msg += `â€¢ <code>/laporan minggu</code> (Minggu Ini)\n`;
    msg += `â€¢ <code>/laporan bulan</code> (Bulan Ini)\n`;
    msg += `â€¢ <code>/laporan tahun</code> (Tahun Ini)\n`;

    return msg;
  }
}

export const telegramService = new TelegramService();


