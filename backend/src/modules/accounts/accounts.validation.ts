import { z } from 'zod';

export const createAccountSchema = z.object({
  name: z.string().min(2, { message: 'Nama akun minimal 2 karakter' }),
  accountType: z.enum(['BANK', 'CASH', 'EWALLET', 'INVESTMENT', 'OTHER']).default('BANK'),
  initialBalance: z.number().default(0),
  currency: z.string().default('IDR'),
});

export const updateAccountSchema = z.object({
  name: z.string().min(2).optional(),
  accountType: z.enum(['BANK', 'CASH', 'EWALLET', 'INVESTMENT', 'OTHER']).optional(),
  isArchived: z.boolean().optional(),
});

export type CreateAccountInput = z.infer<typeof createAccountSchema>;
export type UpdateAccountInput = z.infer<typeof updateAccountSchema>;

