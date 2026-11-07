# Desain Database — Personal Finance Tracker

**Database Provider:** Supabase (PostgreSQL)  
**ORM:** Prisma  
**Schema file:** `backend/prisma/schema.prisma`

---

## Entity Relationship Diagram

```
users ──────────────────┬── accounts ──── transactions
  │                     │                      │
  ├── categories ────────────────────────────► │
  │                     │                      │
  ├── telegram_links     └── [saldo dihitung]  │
  │                                            │
  └── ai_processing_logs                       │
                                               │
telegram_messages (standalone idempotency table)
```

---

## Tabel: `users`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `email` | VARCHAR(255) UNIQUE | Email login |
| `password_hash` | VARCHAR(255) | Hash password (bcrypt/argon2) |
| `full_name` | VARCHAR(150) | Nama lengkap |
| `avatar_url` | TEXT nullable | URL foto profil |
| `is_active` | BOOLEAN | Status aktif akun |
| `created_at` | TIMESTAMP | Waktu registrasi |
| `updated_at` | TIMESTAMP | Auto-update |

---

## Tabel: `accounts`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `user_id` | UUID (FK → users) | Pemilik akun |
| `name` | VARCHAR(100) | Nama akun (cth: BCA, GoPay, Dompet) |
| `account_type` | ENUM | BANK / CASH / EWALLET / INVESTMENT / OTHER |
| `initial_balance` | DECIMAL(15,2) | **Saldo awal saat akun dibuat** |
| `currency` | VARCHAR(10) | Default: IDR |
| `is_archived` | BOOLEAN | Soft-delete |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |

> **⚠️ PENTING — Aturan Perhitungan Saldo:**
> Saldo aktif TIDAK disimpan sebagai kolom yang di-update tiap transaksi.
> Saldo dihitung secara real-time dengan formula:
> ```
> currentBalance = initial_balance + SUM(INCOME transactions) - SUM(EXPENSE transactions)
> ```
> Ini mencegah inkonsistensi data jika transaksi diedit/dihapus.

---

## Tabel: `categories`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `user_id` | UUID nullable (FK → users) | NULL = kategori default sistem |
| `name` | VARCHAR(100) | Nama kategori |
| `type` | ENUM | INCOME atau EXPENSE |
| `icon` | VARCHAR(50) | Nama icon (Material Symbols) |
| `color` | VARCHAR(30) | Hex color string |
| `is_default` | BOOLEAN | Kategori bawaan sistem |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |

**Kategori EXPENSE default:** Makanan & Minuman, Transportasi, Belanja, Kesehatan, Hiburan, Pendidikan, Tagihan, Lainnya  
**Kategori INCOME default:** Gaji, Freelance, Investasi, Hadiah, Lainnya

---

## Tabel: `transactions`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `user_id` | UUID (FK → users) | Pemilik transaksi |
| `account_id` | UUID (FK → accounts) | Akun yang digunakan |
| `category_id` | UUID (FK → categories) | Kategori transaksi |
| `type` | ENUM | INCOME atau EXPENSE |
| `amount` | DECIMAL(15,2) | **Nominal — wajib ada, selalu positif** |
| `description` | VARCHAR(255) | Deskripsi singkat wajib |
| `notes` | TEXT nullable | Catatan tambahan opsional |
| `transaction_date` | TIMESTAMP | Tanggal & waktu transaksi |
| `source` | VARCHAR(30) | MOBILE / TELEGRAM_BOT / MANUAL |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |

**Indeks:** `(user_id, transaction_date)`, `(user_id, type)`, `(account_id)`, `(category_id)`

> **Aturan bisnis penting:**
> - Transaksi tidak boleh disimpan jika `amount` belum ada atau 0
> - `amount` selalu disimpan sebagai nilai positif
> - Jenis (INCOME/EXPENSE) yang menentukan arah pengaruh ke saldo

---

## Tabel: `telegram_links`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `user_id` | UUID (FK → users) | User aplikasi |
| `telegram_user_id` | BIGINT UNIQUE | ID user di Telegram |
| `telegram_chat_id` | BIGINT | Chat ID Telegram |
| `telegram_username` | VARCHAR(100) nullable | @username Telegram |
| `first_name` | VARCHAR(100) nullable | Nama depan Telegram |
| `last_name` | VARCHAR(100) nullable | Nama belakang Telegram |
| `is_linked` | BOOLEAN | Status tautan aktif |
| `created_at` | TIMESTAMP | — |
| `updated_at` | TIMESTAMP | — |

---

## Tabel: `telegram_messages`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `chat_id` | BIGINT | Chat ID Telegram |
| `message_id` | BIGINT | Message ID Telegram |
| `raw_text` | TEXT nullable | Isi pesan asli |
| `status` | VARCHAR(50) | PROCESSED / FAILED / NEED_CLARIFICATION / IGNORED |
| `processed_at` | TIMESTAMP | Waktu diproses |

**UNIQUE CONSTRAINT:** `(chat_id, message_id)` — mencegah pemrosesan pesan ganda (idempotency)

---

## Tabel: `ai_processing_logs`

| Kolom | Tipe | Keterangan |
|---|---|---|
| `id` | UUID (PK) | Primary key |
| `user_id` | UUID nullable (FK → users) | Nullable (Telegram user belum linked) |
| `raw_input` | TEXT | Teks asli yang di-parse |
| `model` | VARCHAR(100) | Model Groq yang digunakan |
| `parsed_result` | JSON nullable | Hasil parsing AI |
| `status` | VARCHAR(50) | SUCCESS / FAILED / NEED_CLARIFICATION |
| `error_message` | TEXT nullable | Error jika gagal |
| `latency_ms` | INT nullable | Waktu respons Groq dalam ms |
| `created_at` | TIMESTAMP | — |

> **Tujuan:** Debugging, monitoring kualitas AI parser, dan audit trail.

