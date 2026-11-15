# Personal Finance Tracker

> Aplikasi pencatatan keuangan pribadi dengan dukungan **Telegram Bot + Groq AI** dan **Flutter Mobile App**.

---

## 📋 Deskripsi

Personal Finance Tracker adalah aplikasi keuangan yang memungkinkan pengguna mencatat pemasukan dan pengeluaran melalui dua media:

1. **Aplikasi Mobile Flutter** — UI modern dengan Material 3
2. **Telegram Bot + AI** — Kirim pesan biasa, AI akan parse dan simpan transaksi secara otomatis

Contoh penggunaan melalui Telegram:
```
Pengguna: "Membeli bensin Rp50.000"
Bot: ✅ Transaksi Dicatat!
     Jenis: Pengeluaran | Nominal: Rp50.000 | Kategori: Transportasi
```

---

## 🛠 Teknologi

| Bagian | Teknologi |
|---|---|
| Mobile | Flutter 3.x, Dart, Riverpod, GoRouter, Dio |
| Backend | Node.js, Express.js, TypeScript (strict) |
| Database | PostgreSQL via **Supabase** |
| ORM | Prisma |
| Auth | JWT |
| Validasi | Zod |
| AI Parser | Groq API (llama-3.3-70b-versatile) |
| Messaging | Telegram Bot API (Webhook) |

---

## 📁 Struktur Project

```
personal-finance-tracker/           # Monorepo root
├── backend/                        # Node.js + Express + TypeScript
│   ├── prisma/                     # Database schema & migrations
│   ├── src/
│   │   ├── config/                 # Env, Database (Prisma client)
│   │   ├── common/                 # Middleware, errors, utils
│   │   ├── modules/                # Feature modules
│   │   │   ├── auth/
│   │   │   ├── users/
│   │   │   ├── accounts/
│   │   │   ├── categories/
│   │   │   ├── transactions/
│   │   │   ├── dashboard/
│   │   │   ├── reports/
│   │   │   ├── telegram/
│   │   │   └── ai-parser/
│   │   ├── services/               # Groq AI, Telegram Bot services
│   │   ├── routes/                 # Route aggregator
│   │   ├── app.ts                  # Express app factory
│   │   └── server.ts               # Entry point
│   └── .env.example
│
├── mobile/                         # Flutter App
│   ├── lib/
│   │   ├── core/                   # Constants, errors, network, router, theme, utils
│   │   ├── features/               # Feature-first structure
│   │   │   ├── authentication/
│   │   │   ├── dashboard/
│   │   │   ├── transactions/
│   │   │   ├── accounts/
│   │   │   ├── categories/
│   │   │   ├── reports/
│   │   │   ├── telegram/
│   │   │   └── settings/
│   │   ├── shared/                 # Reusable widgets, models, providers
│   │   └── main.dart
│   └── pubspec.yaml
│
└── docs/                           # Documentation
```

---

## ⚙️ Persyaratan

- **Node.js** >= 20.x
- **npm** >= 10.x
- **Flutter SDK** >= 3.5.0
- **Dart SDK** >= 3.9.x
- **Supabase Project** (PostgreSQL database)
- **Groq API Key** (opsional untuk AI parsing)
- **Telegram Bot Token** (opsional untuk Telegram integration)

---

## 🚀 Cara Menjalankan Backend

### 1. Setup environment

```bash
cd backend
cp .env.example .env
# Edit .env — isi DATABASE_URL, DIRECT_URL, JWT_SECRET, dll
```

### 2. Install dependencies

```bash
npm install
```

### 3. Generate Prisma client & jalankan migration

```bash
npm run prisma:generate
npm run prisma:migrate   # Butuh Supabase DATABASE_URL aktif
```

### 4. Jalankan server development

```bash
npm run dev
```

Server berjalan di: `http://localhost:5000`  
Health check: `GET http://localhost:5000/api/health`

### 5. Build production

```bash
npm run build
npm start
```

---

## 📱 Cara Menjalankan Flutter

```bash
cd mobile
flutter pub get
flutter run
```

> Pastikan API backend berjalan. Untuk Android Emulator, base URL default menggunakan `10.0.2.2:5000`.  
> Untuk device fisik, ubah `kApiBaseUrl` di `lib/core/constants/app_constants.dart` ke IP lokal server.

---

## 🔐 Konfigurasi Environment

Salin `backend/.env.example` ke `backend/.env` dan isi semua variabel:

| Variabel | Keterangan |
|---|---|
| `DATABASE_URL` | Supabase Transaction Pooler (port 6543) |
| `DIRECT_URL` | Supabase Direct connection (port 5432, untuk migration) |
| `JWT_SECRET` | String acak minimal 32 karakter |
| `GROQ_API_KEY` | API key dari [console.groq.com](https://console.groq.com) |
| `TELEGRAM_BOT_TOKEN` | Token dari [@BotFather](https://t.me/BotFather) di Telegram |

> ⚠️ **JANGAN PERNAH** commit file `.env` ke repository.  
> ⚠️ `GROQ_API_KEY` hanya boleh ada di backend server, **tidak boleh** dimasukkan ke kode Flutter.

---

## 📖 Dokumentasi

- [`docs/architecture.md`](docs/architecture.md) — Arsitektur sistem
- [`docs/database-design.md`](docs/database-design.md) — Desain database & relasi
- [`docs/api-documentation.md`](docs/api-documentation.md) — Daftar endpoint API
- [`docs/development-roadmap.md`](docs/development-roadmap.md) — Roadmap pengembangan
- [`docs/telegram-integration.md`](docs/telegram-integration.md) — Alur integrasi Telegram
- [`docs/free-hosting-guide.md`](docs/free-hosting-guide.md) — Panduan hosting online 100% gratis

