import { PrismaClient } from '@prisma/client';
import { env } from './env.js';

declare global {
  // eslint-disable-next-line no-var
  var prismaGlobal: PrismaClient | undefined;
}

const buildDatasourceUrl = (): string => {
  let url = env.DATABASE_URL;
  // Ensure serverless pool connection settings
  if (!url.includes('connection_limit')) {
    url += (url.includes('?') ? '&' : '?') + 'connection_limit=1';
  }
  if (!url.includes('pool_timeout')) {
    url += '&pool_timeout=25';
  }
  return url;
};

export const prisma: PrismaClient =
  globalThis.prismaGlobal ??
  new PrismaClient({
    datasources: {
      db: {
        url: buildDatasourceUrl(),
      },
    },
    log: env.NODE_ENV === 'development' ? ['query', 'error', 'warn'] : ['error'],
  });

// Always preserve client instance on globalThis in serverless environments (Vercel)
globalThis.prismaGlobal = prisma;
