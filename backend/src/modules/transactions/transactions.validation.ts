import { z } from 'zod';

export const createTransactionSchema = z.object({
  type: z.enum(['INCOME', 'EXPENSE']),
  amount: z.number().positive({ message: 'Nominal transaksi harus lebih besar dari 0' }),
  description: z.string().min(1, { message: 'Deskripsi transaksi wajib diisi' }),
  accountId: z.string().uuid({ message: 'ID Akun tidak valid' }),
  categoryId: z.string().uuid({ message: 'ID Kategori tidak valid' }),
  transactionDate: z.string().datetime().optional().default(() => new Date().toISOString()),
  notes: z.string().optional(),
  source: z.enum(['MOBILE', 'TELEGRAM_BOT', 'MANUAL']).default('MOBILE'),
});

export const transactionQuerySchema = z.object({
  startDate: z.string().optional(),
  endDate: z.string().optional(),
  type: z.enum(['INCOME', 'EXPENSE']).optional(),
  accountId: z.string().uuid().optional(),
  categoryId: z.string().uuid().optional(),
  limit: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 20)),
  offset: z.string().optional().transform((v) => (v ? parseInt(v, 10) : 0)),
});

export type CreateTransactionInput = z.infer<typeof createTransactionSchema>;
export type TransactionQueryInput = z.infer<typeof transactionQuerySchema>;

