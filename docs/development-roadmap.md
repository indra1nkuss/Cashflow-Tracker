# Development Roadmap — Personal Finance Tracker

## Prinsip Pengembangan

- Setiap phase berjalan secara bertahap dan tidak merombak struktur yang sudah ada
- Prioritas: Backend stabil → Telegram Bot → Mobile UI
- Testing dilakukan di akhir setiap major phase

---

## Phase 1 — Project Initialization ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 1–2 hari

Deliverables:
- [x] Monorepo structure `personal-finance-tracker/`
- [x] Backend: Express + TypeScript + Prisma scaffold
- [x] Prisma schema (7 entitas, Supabase-ready)
- [x] Flutter project structure (feature-first)
- [x] Environment configuration (`.env.example`)
- [x] Global error handler, Zod validation, JWT middleware
- [x] Health check endpoint `/api/health`
- [x] Placeholder screens: Splash, Login, Register, Dashboard
- [x] Dokumentasi lengkap (README, architecture, database, API, roadmap, telegram)
- [x] `.gitignore` komprehensif

---

## Phase 2 — Database Implementation ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 1–2 hari

Tasks:
- [x] Setup Supabase project
- [x] Konfigurasi `DATABASE_URL` dan `DIRECT_URL` di `.env`
- [x] Jalankan `npx prisma migrate dev --name init`
- [x] Seed data: 13 kategori default sistem (INCOME/EXPENSE)
- [x] Verifikasi schema di Supabase Studio

---

## Phase 3 — Authentication ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 2–3 hari

Tasks:
- [x] Install `bcryptjs` untuk proper password hashing (10 salt rounds)
- [x] Implementasi `AuthService.register` dengan real password hashing & auto-create default account
- [x] Implementasi `AuthService.login` dengan real bcrypt comparison & JWT token generation
- [x] Flutter: `UserModel` & `AuthState` (domain models)
- [x] Flutter: `AuthRepository` (HTTP Dio + storage token persistence)
- [x] Flutter: `AuthNotifier` (Riverpod StateNotifier) — login/register/logout/checkAuth
- [x] Flutter: Token persistence di `FlutterSecureStorage`
- [x] Flutter: Auto-redirect reaktif berdasarkan auth state di `GoRouter`
- [x] Flutter: Form login & register terhubung langsung ke backend
- [x] Flutter: User profile & Logout button di `SettingsScreen`

---

## Phase 4 — Transaction CRUD ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 3–4 hari

Tasks:
- [x] Backend: Verifikasi semua CRUD endpoints transactions berjalan
- [x] Backend: Verifikasi CRUD accounts & categories
- [x] Flutter: `AccountModel`, `CategoryModel`, `TransactionModel` (domain models)
- [x] Flutter: `AccountsRepository`, `CategoriesRepository`, `TransactionsRepository` (data layer)
- [x] Flutter: `AccountsNotifier`, `CategoriesNotifier`, `TransactionsNotifier` (Riverpod AsyncNotifier)
- [x] Flutter: Layar daftar transaksi dengan filter (Semua / Pengeluaran / Pemasukan)
- [x] Flutter: Form tambah transaksi lengkap (tipe, nominal, akun, kategori, tanggal, catatan)
- [x] Flutter: Konfirmasi dialog hapus transaksi & auto-update saldo
- [x] Flutter: Layar Akun dengan saldo real-time & modal tambah akun
- [x] Flutter: Layar Kelola Kategori (TabBar Pengeluaran vs Pemasukan) & modal tambah kategori

---

## Phase 5 — Dashboard ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 2–3 hari

Tasks:
- [x] Backend: Endpoint `/api/dashboard/summary` (total balance, monthly income/expense, 5 recent transactions)
- [x] Flutter: `DashboardSummaryModel` & `DashboardRepository`
- [x] Flutter: `DashboardNotifier` (Riverpod)
- [x] Flutter: Kartu total saldo (kalkulasi konsisten dari saldo awal + pemasukan - pengeluaran)
- [x] Flutter: Kartu ringkasan Pemasukan & Pengeluaran bulan berjalan
- [x] Flutter: List horizontal akun & dompet
- [x] Flutter: Daftar 5 transaksi terbaru dengan icon & warna semantik
- [x] Flutter: Pull-to-refresh & Floating Action Button ke form transaksi

---

## Phase 6 — Telegram Integration ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 3–5 hari

Tasks:
- [x] Webhook endpoint `/api/telegram/webhook`
- [x] Generator kode tautan akun 6 karakter (`POST /api/telegram/generate-code`)
- [x] Handler perintah pairing `/link PFT-XXXX` & auto-link akun
- [x] Penyimpanan relasi di tabel `telegram_links`
- [x] Flutter: Layar Telegram Link (`/telegram-link`) fungsional dengan copyable code & status
- [x] Perlindungan pesan duplikat via idempotency check `(chat_id, message_id)`
- [x] Endpoint pemutusan tautan `DELETE /api/telegram/unlink`
- [x] Perintah laporan Telegram: `/laporan hari`, `/laporan minggu`, `/laporan bulan`, `/laporan tahun`
- [x] Perintah pembatalan transaksi terakhir via Telegram: `/batal` / `/undo`

---

## Phase 7 — Groq AI Transaction Parser ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 2–3 hari

Tasks:
- [x] Integrasi Groq SDK (`llama-3.3-70b-versatile`)
- [x] Structured JSON system prompt khusus parsing keuangan Indonesia
- [x] Ekstraksi EXPENSE, INCOME, nominal (angka, titik, singkatan 'rb', 'jt'), kategori, deskripsi
- [x] Klarifikasi otomatis jika nominal belum dicantumkan
- [x] Audit trail & logging setiap proses AI ke tabel `ai_processing_logs`
- [x] Flutter: `AiTransactionDialog` interaktif untuk pencatatan AI cepat langsung di aplikasi

---

## Phase 8 — Mobile UI Implementation ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 5–7 hari

Tasks:
- [x] Desain Material 3 di seluruh layar aplikasi
- [x] Layar Laporan Keuangan dengan grafik Donut Chart (`fl_chart`)
- [x] Breakdown pengeluaran per kategori lengkap dengan persentase & progress bar
- [x] Navigasi bulan interaktif (`< Bulan Tahun >`) & kalkulasi cashflow
- [x] Layar Akun dengan saldo real-time & modal tambah akun
- [x] Layar Kategori (TabBar Pengeluaran vs Pemasukan) & modal tambah kategori
- [x] Layar Pengaturan dengan profil user dan tombol logout

---

## Phase 9 — Synchronization & Testing ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 3–5 hari

Tasks:
- [x] Backend: Suite tes integrasi otomatis (`backend/tests/api.test.ts`) menggunakan Node test runner
- [x] 9 tes integrasi otomatis (Health, Auth validation, JWT, Protected routes, Accounts, Categories, Telegram code, Webhook idempotency)
- [x] Flutter: static analysis (`dart analyze`) 100% clean dengan 0 error dan 0 warning

---

## Phase 10 — Deployment Preparation ✅ SELESAI

**Status:** Completed  
**Durasi estimasi:** 2–3 hari

Tasks:
- [x] Multi-stage production `Dockerfile` (Node 22-alpine + Prisma generate + build)
- [x] `docker-compose.yml` lengkap dengan healthcheck probe
- [x] `.dockerignore` untuk optimasi image size
- [x] Database migration & seeding siap pakai di Supabase PostgreSQL
- [x] Dokumentasi deployment lengkap di README.md & docs/

---

## Prioritas MVP (Minimum Viable Product)

Untuk versi awal yang sudah bisa digunakan:

```
Phase 2 (DB) → Phase 3 (Auth) → Phase 4 (CRUD) → Phase 6 (Telegram) → Phase 7 (AI)
```

Setelah MVP, lanjutkan Phase 5 (Dashboard), 8 (Mobile UI), 9 (Testing), 10 (Deployment).

