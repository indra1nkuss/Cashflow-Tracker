import { z } from 'zod';

export const parseMessageSchema = z.object({
  message: z.string().min(1, { message: 'Teks pesan tidak boleh kosong' }),
});

export type ParseMessageInput = z.infer<typeof parseMessageSchema>;

