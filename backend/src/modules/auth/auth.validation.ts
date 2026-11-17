import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email({ message: 'Format email tidak valid' }),
  password: z.string().min(8, { message: 'Password minimal 8 karakter' }),
  fullName: z.string().min(2, { message: 'Nama lengkap minimal 2 karakter' }),
});

export const loginSchema = z.object({
  email: z.string().email({ message: 'Format email tidak valid' }),
  password: z.string().min(1, { message: 'Password wajib diisi' }),
});

export const forgotPasswordSchema = z.object({
  email: z.string().email({ message: 'Format email tidak valid' }),
});

export const resetPasswordSchema = z.object({
  email: z.string().email({ message: 'Format email tidak valid' }),
  otp: z.string().length(6, { message: 'Kode OTP harus 6 digit' }),
  newPassword: z.string().min(8, { message: 'Password baru minimal 8 karakter' }),
});

export type RegisterInput = z.infer<typeof registerSchema>;
export type LoginInput = z.infer<typeof loginSchema>;
export type ForgotPasswordInput = z.infer<typeof forgotPasswordSchema>;
export type ResetPasswordInput = z.infer<typeof resetPasswordSchema>;

