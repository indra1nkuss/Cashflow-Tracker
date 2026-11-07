import { z } from 'zod';

export const linkTelegramSchema = z.object({
  linkCode: z.string().min(4, { message: 'Kode tautan Telegram tidak valid' }),
});

export const telegramWebhookSchema = z.object({
  update_id: z.number(),
  message: z
    .object({
      message_id: z.number(),
      from: z.object({
        id: z.number(),
        is_bot: z.boolean().optional(),
        first_name: z.string().optional(),
        last_name: z.string().optional(),
        username: z.string().optional(),
      }),
      chat: z.object({
        id: z.number(),
        type: z.string().optional(),
      }),
      text: z.string().optional(),
      date: z.number().optional(),
    })
    .optional(),
});

export type TelegramWebhookPayload = z.infer<typeof telegramWebhookSchema>;

