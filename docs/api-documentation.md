# API Documentation — Personal Finance Tracker

**Base URL:** `http://localhost:5000/api`  
**Auth:** Bearer JWT (kecuali endpoint public)

---

## Health Check

### `GET /api/health`
**Auth:** Public

**Response:**
```json
{
  "success": true,
  "message": "Personal Finance Tracker API is running",
  "timestamp": "2026-01-01T00:00:00.000Z",
  "version": "1.0.0"
}
```

---

## Authentication `/api/auth`

### `POST /api/auth/register`
**Auth:** Public

**Request body:**
```json
{ "email": "user@example.com", "password": "min8chars", "fullName": "Nama Lengkap" }
```

**Response (201):**
```json
{
  "success": true,
  "message": "Registrasi berhasil",
  "data": {
    "user": { "id": "uuid", "email": "...", "fullName": "..." },
    "token": "JWT..."
  }
}
```

---

### `POST /api/auth/login`
**Auth:** Public

**Request body:**
```json
{ "email": "user@example.com", "password": "mypassword" }
```

**Response (200):**
```json
{
  "success": true,
  "data": { "user": {...}, "token": "JWT..." }
}
```

---

## Users `/api/users`

### `GET /api/users/me`
**Auth:** Required

Returns current authenticated user's profile.

---

## Dashboard `/api/dashboard`

### `GET /api/dashboard/summary`
**Auth:** Required

Returns current month's total balance, income, expense, accounts summary, and 5 recent transactions.

---

## Accounts `/api/accounts`

### `GET /api/accounts`
**Auth:** Required

Returns all accounts with **computed current balance** (`initialBalance + SUM(income) - SUM(expense)`).

### `POST /api/accounts`
**Auth:** Required

**Request body:**
```json
{ "name": "BCA", "accountType": "BANK", "initialBalance": 1000000, "currency": "IDR" }
```

### `GET /api/accounts/:id`
**Auth:** Required

### `PATCH /api/accounts/:id`
**Auth:** Required

---

## Categories `/api/categories`

### `GET /api/categories`
**Auth:** Required  
**Query:** `?type=INCOME` or `?type=EXPENSE`

Returns user's custom + system default categories.

### `POST /api/categories`
**Auth:** Required

```json
{ "name": "Transportasi", "type": "EXPENSE", "icon": "directions_car", "color": "#2563EB" }
```

### `PATCH /api/categories/:id`
**Auth:** Required

---

## Transactions `/api/transactions`

### `GET /api/transactions`
**Auth:** Required  
**Query params:**

| Param | Type | Description |
|---|---|---|
| `startDate` | ISO string | Filter mulai tanggal |
| `endDate` | ISO string | Filter sampai tanggal |
| `type` | INCOME / EXPENSE | Filter jenis |
| `accountId` | UUID | Filter per akun |
| `categoryId` | UUID | Filter per kategori |
| `limit` | number | Default: 20 |
| `offset` | number | Default: 0 |

### `POST /api/transactions`
**Auth:** Required

```json
{
  "type": "EXPENSE",
  "amount": 50000,
  "description": "Membeli bensin",
  "accountId": "uuid",
  "categoryId": "uuid",
  "transactionDate": "2026-01-01T10:00:00.000Z",
  "source": "MOBILE"
}
```

> **Aturan:** `amount` wajib positif. Nominal 0 atau negatif akan ditolak (Zod validation).

### `GET /api/transactions/:id`
**Auth:** Required

### `DELETE /api/transactions/:id`
**Auth:** Required

---

## Reports `/api/reports`

### `GET /api/reports/monthly`
**Auth:** Required  
**Query:** `?year=2026&month=11`

Returns monthly income/expense totals and category breakdown.

---

## Telegram `/api/telegram`

### `POST /api/telegram/webhook`
**Auth:** Public (Telegram server IP, secured by webhook secret header)

Receives Telegram updates. Responds immediately with `{ ok: true }` and processes asynchronously.

### `GET /api/telegram/link-status`
**Auth:** Required

Returns whether the authenticated user's Telegram account is linked.

---

## AI Parser `/api/ai-parser`

### `POST /api/ai-parser/parse`
**Auth:** Required

```json
{ "message": "Membeli bensin Rp50.000" }
```

**Response (200):**
```json
{
  "success": true,
  "data": {
    "isTransaction": true,
    "type": "EXPENSE",
    "amount": 50000,
    "category": "Transportasi",
    "description": "Membeli bensin",
    "needsClarification": false
  }
}
```

**When clarification needed:**
```json
{
  "data": {
    "isTransaction": true,
    "needsClarification": true,
    "clarificationMessage": "Berapa nominal pengeluaran untuk bensin?"
  }
}
```

> **Catatan:** Endpoint ini hanya melakukan parsing. Penyimpanan transaksi tetap dilakukan via `POST /api/transactions` setelah pengguna mengkonfirmasi.

---

## Standard Error Response

```json
{
  "success": false,
  "message": "Pesan error yang menjelaskan masalah",
  "errors": [
    { "field": "amount", "message": "Nominal wajib diisi", "code": "too_small" }
  ]
}
```

| HTTP Status | Keterangan |
|---|---|
| 400 | Bad Request |
| 401 | Unauthorized — token tidak valid/expired |
| 403 | Forbidden |
| 404 | Resource tidak ditemukan |
| 422 | Validation failed |
| 500 | Internal Server Error |

