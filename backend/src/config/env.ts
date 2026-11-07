import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
  PORT: z.string().default('5000').transform((val) => parseInt(val, 10)),
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  DATABASE_URL: z.string().min(1, { message: 'DATABASE_URL is required' }),
  DIRECT_URL: z.string().optional(),
  JWT_SECRET: z.string().min(8, { message: 'JWT_SECRET must be at least 8 characters long' }).default('default_dev_jwt_secret_change_me_in_production'),
  GROQ_API_KEY: z.string().optional().default(''),
  GROQ_MODEL: z.string().default('llama-3.3-70b-versatile'),
  TELEGRAM_BOT_TOKEN: z.string().optional().default(''),
  TELEGRAM_WEBHOOK_SECRET: z.string().optional().default(''),
  APP_TIMEZONE: z.string().default('Asia/Jakarta'),
});

const parseEnv = () => {
  const parsed = envSchema.safeParse(process.env);

  if (!parsed.success) {
    console.error('❌ Invalid environment variables configuration:');
    console.error(parsed.error.format());
    // In development or when initializing project, we provide fallbacks if DATABASE_URL is not set yet
    if (process.env.NODE_ENV !== 'production' && !process.env.DATABASE_URL) {
      console.warn('⚠️ Warning: DATABASE_URL not set. Using local development fallback.');
      return envSchema.parse({
        ...process.env,
        DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/finance_tracker?schema=public',
      });
    }
    throw new Error('Environment validation failed');
  }

  return parsed.data;
};

export const env = parseEnv();
export type Environment = z.infer<typeof envSchema>;

