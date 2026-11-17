import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { RegisterInput, LoginInput } from './auth.validation.js';
import { prisma } from '../../config/database.js';
import { env } from '../../config/env.js';
import { BadRequestError, UnauthorizedError } from '../../common/errors/app-error.js';
import { telegramBotService } from '../../services/telegram-bot.service.js';

export class AuthService {
  public async register(input: RegisterInput) {
    const existing = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (existing) {
      throw new BadRequestError('Email sudah terdaftar dalam sistem');
    }

    // Secure password hashing with bcryptjs (salt rounds: 10)
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.password, salt);

    const { user } = await prisma.$transaction(async (tx) => {
      const newUser = await tx.user.create({
        data: {
          email: input.email,
          passwordHash,
          fullName: input.fullName,
        },
        select: {
          id: true,
          email: true,
          fullName: true,
          createdAt: true,
        },
      });

      // Automatically create a default account for the new user
      await tx.account.create({
        data: {
          userId: newUser.id,
          name: 'Dompet Utama',
          accountType: 'CASH',
          initialBalance: 0,
        },
      });

      return { user: newUser };
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return { user, token };
  }

  public async login(input: LoginInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (!user) {
      throw new UnauthorizedError('Kredensial tidak valid');
    }

    const isMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedError('Kredensial tidak valid');
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
      },
      token,
    };
  }

  /**
   * Forgot Password Step 1: Generate OTP dan kirim via Telegram.
   * Jika akun belum terhubung Telegram, kembalikan error dengan petunjuk.
   */
  public async forgotPassword(email: string): Promise<{ method: string; hint: string }> {
    // Always return success-looking response to prevent email enumeration
    const user = await prisma.user.findUnique({ where: { email } });

    if (!user) {
      // Don't reveal whether email exists
      return {
        method: 'telegram',
        hint: 'Jika email terdaftar dan akun terhubung ke Telegram, kode OTP akan dikirim ke bot Telegram Anda dalam beberapa saat.',
      };
    }

    // Check if user has linked Telegram
    const telegramLink = await prisma.telegramLink.findFirst({
      where: { userId: user.id, isLinked: true },
    });

    if (!telegramLink) {
      throw new BadRequestError(
        'Akun ini belum terhubung ke Telegram. Reset password hanya bisa dilakukan via Telegram Bot. ' +
        'Silakan login terlebih dahulu menggunakan password lama, lalu hubungkan akun Telegram Anda di menu Pengaturan.'
      );
    }

    // Delete existing unused OTPs for this user
    await prisma.passwordResetOTP.deleteMany({ where: { userId: user.id } });

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 menit

    await prisma.passwordResetOTP.create({
      data: { userId: user.id, otp, expiresAt },
    });

    // Send OTP via Telegram
    const otpMessage =
      `🔐 <b>Reset Password - Cashflow Tracker</b>\n\n` +
      `Halo <b>${user.fullName}</b>,\n\n` +
      `Anda meminta reset password. Gunakan kode OTP berikut:\n\n` +
      `<code>${otp}</code>\n\n` +
      `⏱️ Kode berlaku selama <b>10 menit</b>.\n` +
      `🚫 Jika Anda tidak meminta reset password, abaikan pesan ini.`;

    await telegramBotService.sendMessage(telegramLink.telegramChatId.toString(), otpMessage);

    return {
      method: 'telegram',
      hint: `Kode OTP telah dikirim ke bot Telegram Anda. Periksa chat dengan bot Cashflow Tracker.`,
    };
  }

  /**
   * Forgot Password Step 2: Verifikasi OTP dan set password baru.
   */
  public async resetPassword(email: string, otp: string, newPassword: string): Promise<void> {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      throw new BadRequestError('Email tidak ditemukan');
    }

    const otpRecord = await prisma.passwordResetOTP.findFirst({
      where: { userId: user.id, otp, used: false },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestError('Kode OTP tidak valid atau sudah digunakan');
    }

    if (new Date() > otpRecord.expiresAt) {
      await prisma.passwordResetOTP.delete({ where: { id: otpRecord.id } });
      throw new BadRequestError('Kode OTP sudah kedaluwarsa. Silakan minta kode baru.');
    }

    if (newPassword.length < 8) {
      throw new BadRequestError('Password baru minimal 8 karakter');
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await prisma.$transaction([
      prisma.user.update({ where: { id: user.id }, data: { passwordHash } }),
      prisma.passwordResetOTP.update({ where: { id: otpRecord.id }, data: { used: true } }),
    ]);

    // Notify user via Telegram
    const telegramLink = await prisma.telegramLink.findFirst({
      where: { userId: user.id, isLinked: true },
    });
    if (telegramLink) {
      await telegramBotService.sendMessage(
        telegramLink.telegramChatId.toString(),
        `✅ <b>Password Berhasil Diubah!</b>\n\nPassword akun Cashflow Tracker Anda telah berhasil diperbarui. Silakan login dengan password baru Anda.\n\n🔒 Jika Anda tidak melakukan perubahan ini, segera hubungi kami.`
      );
    }
  }
}

export const authService = new AuthService();

