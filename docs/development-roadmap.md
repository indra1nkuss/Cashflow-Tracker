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

## Phase 6 — Telegram Integration

**Status:** Belum dimulai  
**Durasi estimasi:** 3–5 hari

Tasks:
- [ ] Buat Telegram Bot melalui @BotFather
- [ ] Daftarkan Webhook ke Telegram API
- [ ] Implementasi mekanisme link akun (kode OTP atau deep link)
- [ ] `TelegramLink` creation flow di backend
- [ ] Flutter: Layar Telegram Link (`/telegram-link`) fungsional
- [ ] Testing: kirim pesan → transaksi tersimpan → reply konfirmasi
- [ ] Testing: pesan duplikat → ditolak (idempotency)

---

## Phase 7 — Groq AI Transaction Parser

**Status:** Belum dimulai  
**Durasi estimasi:** 2–3 hari

Tasks:
- [ ] Setup Groq API key di `.env`
- [ ] Fine-tune system prompt untuk parsing bahasa Indonesia
- [ ] Testing: berbagai format pesan (nominal dengan titik, koma, singkatan)
- [ ] Handling: pesan tanpa nominal → minta klarifikasi
- [ ] Logging & monitoring kualitas parsing via `ai_processing_logs`
- [ ] Rate limiting Groq API calls

---

## Phase 8 — Mobile UI Implementation

**Status:** Belum dimulai  
**Durasi estimasi:** 5–7 hari

Tasks:
- [ ] Flutter: Desain lengkap semua screen (Material 3)
- [ ] Flutter: Layar Laporan dengan grafik (`fl_chart`)
- [ ] Flutter: Layar Kategori (list, tambah, edit)
- [ ] Flutter: Layar Akun (saldo per akun, tambah, edit)
- [ ] Flutter: Layar Pengaturan (profil, Telegram link, tema)
- [ ] Flutter: Shimmer loading states
- [ ] Flutter: Empty states yang informatif

---

## Phase 9 — Synchronization & Testing

**Status:** Belum dimulai  
**Durasi estimasi:** 3–5 hari

Tasks:
- [ ] Backend: Unit tests (Vitest/Jest) untuk services kritis
- [ ] Backend: Integration tests untuk endpoints utama
- [ ] Flutter: Widget tests
- [ ] E2E testing alur: Login → Tambah Transaksi → Cek Dashboard
- [ ] E2E testing alur Telegram: pesan → transaksi tersimpan
- [ ] Load testing Groq API handling

---

## Phase 10 — Deployment

**Status:** Belum dimulai  
**Durasi estimasi:** 2–3 hari

Tasks:
- [ ] Setup CI/CD (GitHub Actions)
- [ ] Backend: Deploy ke Railway / Render / Fly.io
- [ ] Configure environment variables di hosting
- [ ] Update Telegram Webhook URL ke domain production
- [ ] Flutter: Build APK / App Bundle untuk Android
- [ ] Flutter: Build IPA untuk iOS (opsional)
- [ ] Monitoring: Setup error logging (Sentry opsional)

---

## Prioritas MVP (Minimum Viable Product)

Untuk versi awal yang sudah bisa digunakan:

```
Phase 2 (DB) → Phase 3 (Auth) → Phase 4 (CRUD) → Phase 6 (Telegram) → Phase 7 (AI)
```

Setelah MVP, lanjutkan Phase 5 (Dashboard), 8 (Mobile UI), 9 (Testing), 10 (Deployment).

