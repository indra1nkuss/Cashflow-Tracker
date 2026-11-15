import { describe, it, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { createApp } from '../src/app.js';
import { prisma } from '../src/config/database.js';
import type { Server } from 'node:http';

describe('Personal Finance Tracker - API Integration Tests', () => {
  let server: Server;
  let baseUrl: string;
  let authToken: string;
  const testEmail = `test_runner_${Date.now()}@example.com`;
  const testPassword = 'Password123!';

  before(async () => {
    const app = createApp();
    await new Promise<void>((resolve) => {
      server = app.listen(0, () => {
        const addr = server.address();
        if (typeof addr === 'object' && addr !== null) {
          baseUrl = `http://localhost:${addr.port}/api`;
        }
        resolve();
      });
    });
  });

  after(async () => {
    // Clean up test user
    try {
      await prisma.user.deleteMany({ where: { email: testEmail } });
    } catch (_) {}
    await prisma.$disconnect();
    await new Promise<void>((resolve) => server.close(() => resolve()));
  });

  it('1. Health check endpoint responds with success', async () => {
    const res = await fetch(`${baseUrl}/health`);
    assert.equal(res.status, 200);
    const body = (await res.json()) as { success: boolean; message: string };
    assert.equal(body.success, true);
    assert.match(body.message, /running/i);
  });

  it('2. Register rejects invalid email format', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'invalid-email-address',
        password: testPassword,
        fullName: 'Test User',
      }),
    });
    assert.equal(res.status, 422);
    const body = (await res.json()) as { success: boolean };
    assert.equal(body.success, false);
  });

  it('3. Register creates user, default account, and returns JWT', async () => {
    const res = await fetch(`${baseUrl}/auth/register`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: testEmail,
        password: testPassword,
        fullName: 'Integration Test User',
      }),
    });
    assert.equal(res.status, 201);
    const body = (await res.json()) as {
      success: boolean;
      data: { token: string; user: { id: string; email: string } };
    };
    assert.equal(body.success, true);
    assert.ok(body.data.token);
    assert.equal(body.data.user.email, testEmail);
    authToken = body.data.token;
  });

  it('4. Protected route rejects requests without Authorization header', async () => {
    const res = await fetch(`${baseUrl}/users/me`);
    assert.equal(res.status, 401);
  });

  it('5. Protected route allows access with valid Bearer token', async () => {
    const res = await fetch(`${baseUrl}/users/me`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    assert.equal(res.status, 200);
    const body = (await res.json()) as { success: boolean; data: { email: string } };
    assert.equal(body.success, true);
    assert.equal(body.data.email, testEmail);
  });

  it('6. Fetch accounts returns auto-created default account with balance', async () => {
    const res = await fetch(`${baseUrl}/accounts`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    assert.equal(res.status, 200);
    const body = (await res.json()) as { success: boolean; data: Array<{ name: string; currentBalance: number }> };
    assert.equal(body.success, true);
    assert.ok(body.data.length >= 1);
    assert.equal(body.data[0]?.name, 'Dompet Utama');
  });

  it('7. Fetch categories returns seeded system categories', async () => {
    const res = await fetch(`${baseUrl}/categories`, {
      headers: { Authorization: `Bearer ${authToken}` },
    });
    assert.equal(res.status, 200);
    const body = (await res.json()) as { success: boolean; data: Array<{ name: string; type: string }> };
    assert.equal(body.success, true);
    assert.ok(body.data.length >= 10);
  });

  it('8. Telegram generate-code creates a valid pairing code', async () => {
    const res = await fetch(`${baseUrl}/telegram/generate-code`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${authToken}` },
    });
    assert.equal(res.status, 200);
    const body = (await res.json()) as { success: boolean; data: { code: string } };
    assert.equal(body.success, true);
    assert.match(body.data.code, /^PFT-\d{4}$/);
  });

  it('9. Telegram webhook rejects duplicate messages via idempotency check', async () => {
    const payload = {
      update_id: 999999,
      message: {
        message_id: 888888,
        from: { id: 777777, is_bot: false, first_name: 'IdempotencyTester' },
        chat: { id: 777777, type: 'private' },
        text: 'Duplicate test',
      },
    };

    // First call
    const res1 = await fetch(`${baseUrl}/telegram/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    assert.equal(res1.status, 200);

    // Second call with same message_id & chat_id
    const res2 = await fetch(`${baseUrl}/telegram/webhook`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });
    assert.equal(res2.status, 200);
  });
});

