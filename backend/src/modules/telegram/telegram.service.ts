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
        await telegramBotService.sendMessage(msg.chat.id, '❌ <b>User tidak ditemukan.</b>');
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
        `🎉 <b>Selamat, Akun Berhasil Ditautkan!</b>\n\n` +
        `Halo <b>${user.fullName}</b>, akun Telegram Anda kini terhubung dengan <b>Personal Finance Tracker</b>.\n\n` +
        `Sekarang Anda dapat mencatat keuangan dengan mengetik pesan biasa, contoh:\n` +
        `• <i>"Beli bensin GoPay 40.000"</i>\n` +
        `• <i>"Makan siang cash 25rb"</i>\n` +
        `• <i>"Diterima gaji BNI 5.000.000"</i>\n\n` +
        `Ketik <code>/help</code> untuk melihat daftar perintah bantuan.`;

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
        'Silakan buka aplikasi <b>Personal Finance Tracker</b>, buka menu <i>Pengaturan > Hubungkan Telegram</i>, lalu kirimkan kode tautan ke sini.\n\n' +
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
        `• <i>"Beli bensin GoPay 40.000"</i>\n` +
        `• <i>"Makan siang tunai 25rb"</i>\n` +
        `• <i>"Diterima gaji BNI 5.000.000"</i>\n\n` +
        `<b>Perintah Laporan & Bantuan:</b>\n` +
        `• <code>/laporan hari</code> — Laporan keuangan hari ini\n` +
        `• <code>/laporan minggu</code> — Laporan keuangan minggu ini\n` +
        `• <code>/laporan bulan</code> — Laporan keuangan bulan ini\n` +
        `• <code>/laporan tahun</code> — Laporan keuangan tahun ini\n` +
        `• <code>/batal</code> — Batalkan transaksi terakhir\n` +
        `• <code>/status</code> — Cek status akun yang terhubung`
      );
      await this.updateMessageStatus(chatId, messageId, 'PROCESSED');
      return;
    }

    if (text === '/status') {
      await telegramBotService.sendMessage(
        msg.chat.id,
        `ℹ️ <b>Status Akun</b>\n\n` +
        `👤 <b>Nama:</b> ${link.user.fullName}\n` +
        `📧 <b>Email:</b> ${link.user.email}\n` +
        `🟢 <b>Status:</b> Terhubung`
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
          'ℹ️ Tidak ada transaksi via Telegram yang dapat dibatalkan saat ini.'
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
        `🗑️ <b>Transaksi Terakhir Dibatalkan!</b>\n\n` +
        `• <b>Keterangan:</b> ${lastTx.description}\n` +
        `• <b>Nominal:</b> ${formattedAmount}\n\n` +
        `<i>Transaksi telah dihapus dari pencatatan keuangan Anda.</i>`
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
        '⚠️ <b>Informasi transaksi belum lengkap.</b>\nMohon sebutkan nominal transaksi dan nama akun/dompet.\nContoh:\n• <i>"Beli bensin GoPay 40rb"</i>\n• <i>"Diterima gaji BNI 5jt"</i>';
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
        Logger.info(`Auto-created account: ${mentionedAccount} (${detectedType}) for user ${link.userId}`);
      }
    } else {
      // Tidak ada nama akun disebutkan -> tanya user
      const clarifyText =
        parsed.type === 'INCOME'
          ? '❓ <b>Diterima ke akun mana?</b>\nContoh: <i>"diterima gaji BNI 5jt"</i> atau <i>"terima transferan GoPay 200rb"</i>'
          : '❓ <b>Dibayar dari akun mana?</b>\nContoh: <i>"beli bensin GoPay 50rb"</i> atau <i>"bayar listrik BCA 150rb"</i>';

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

    const typeEmoji = transaction.type === 'INCOME' ? '🟢' : '🔴';
    const typeLabel = transaction.type === 'INCOME' ? 'Pemasukan' : 'Pengeluaran';

    const reply =
      `✅ <b>Transaksi Berhasil Dicatat!</b>\n` +
      `────────────────────────────\n` +
      `<b>Jenis:</b>        ${typeEmoji} ${typeLabel}\n` +
      `<b>Nominal:</b>      <b>${formattedAmount}</b>\n` +
      `<b>Kategori:</b>     ${category.name}\n` +
      `<b>Deskripsi:</b>    ${transaction.description}\n` +
      `<b>Akun / Dompet:</b> 💳 ${account.name}\n` +
      `────────────────────────────\n` +
      `<i>💡 Ketik /batal jika salah mencatat</i>`;

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

    const makeRow = (left: string, right: string) => {
      const col1 = 13;
      const col2 = 14;
      const l = left.padEnd(col1).slice(0, col1);
      const r = right.padStart(col2).slice(0, col2);
      return `│ ${l} │ ${r} │`;
    };

    const netSign = report.netCashflow > 0 ? '+' : '';
    const netFormatted = `${netSign}${fmt(report.netCashflow)}`;
    const incomeFormatted = fmt(report.totalIncome);
    const expenseFormatted = fmt(report.totalExpense);

    const top = '┌' + '─'.repeat(15) + '┬' + '─'.repeat(16) + '┐';
    const mid = '├' + '─'.repeat(15) + '┼' + '─'.repeat(16) + '┤';
    const bot = '└' + '─'.repeat(15) + '┴' + '─'.repeat(16) + '┘';
    const head = '│' + ' RINGKASAN ARUS KAS '.padStart(24).padEnd(32) + '│';

    let msg = `📊 <b>LAPORAN KEUANGAN</b>\n`;
    msg += `📅 <b>Periode:</b> ${report.periodLabel}\n`;
    msg += `👤 <b>Pengguna:</b> ${userName}\n\n`;

    msg += `<pre>\n`;
    msg += `${top}\n`;
    msg += `${head}\n`;
    msg += `${mid}\n`;
    msg += `${makeRow('Pemasukan', incomeFormatted)}\n`;
    msg += `${makeRow('Pengeluaran', expenseFormatted)}\n`;
    msg += `${mid}\n`;
    msg += `${makeRow('Selisih (Net)', netFormatted)}\n`;
    msg += `${bot}\n`;
    msg += `</pre>\n`;
    msg += `📝 <b>Total Transaksi:</b> ${report.transactionCount} catatan\n`;

    if (report.expenseCategories.length > 0) {
      msg += `\n🔴 <b>Rincian Pengeluaran:</b>\n`;
      for (const cat of report.expenseCategories) {
        const pct =
          report.totalExpense > 0
            ? ((cat.total / report.totalExpense) * 100).toFixed(0)
            : '0';
        msg += `• <b>${cat.name}:</b> ${fmt(cat.total)} <i>(${pct}%)</i>\n`;
      }
    }

    if (report.incomeCategories.length > 0) {
      msg += `\n🟢 <b>Rincian Pemasukan:</b>\n`;
      for (const cat of report.incomeCategories) {
        msg += `• <b>${cat.name}:</b> ${fmt(cat.total)}\n`;
      }
    }

    if (report.transactionCount === 0) {
      msg += `\n<i>Belum ada transaksi tercatat pada periode ini.</i>\n`;
    }

    msg += `\n💡 <i>Pilihan perintah laporan:</i>\n`;
    msg += `• <code>/laporan hari</code> (Hari Ini)\n`;
    msg += `• <code>/laporan minggu</code> (Minggu Ini)\n`;
    msg += `• <code>/laporan bulan</code> (Bulan Ini)\n`;
    msg += `• <code>/laporan tahun</code> (Tahun Ini)\n`;

    return msg;
  }
}

export const telegramService = new TelegramService();
