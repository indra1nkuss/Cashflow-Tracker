import { createApp } from '../src/app.js';
import { prisma } from '../src/config/database.js';

const app = createApp();

// Eagerly connect Prisma in serverless context
void prisma.$connect();

export default app;
