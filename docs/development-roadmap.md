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

## Phase 2 — Database Implementation

**Status:** Belum dimulai  
**Durasi estimasi:** 1–2 hari

Tasks:
- [ ] Setup Supabase project
- [ ] Konfigurasi `DATABASE_URL` dan `DIRECT_URL` di `.env`
- [ ] Jalankan `npx prisma migrate dev --name init`
- [ ] Seed data: kategori default sistem (INCOME/EXPENSE)
- [ ] Verifikasi schema di Supabase Studio
- [ ] Tambahkan Supabase Row-Level Security (RLS) policies opsional

---

## Phase 3 — Authentication

**Status:** Belum dimulai  
**Durasi estimasi:** 2–3 hari

Tasks:
- [ ] Install `bcrypt` / `argon2` untuk proper password hashing
- [ ] Implementasi `AuthService.register` dengan real password hashing
- [ ] Implementasi `AuthService.login` dengan real comparison
- [ ] Refresh token mechanism (opsional untuk MVP)
- [ ] Flutter: `AuthNotifier` (Riverpod) — login/register/logout state
- [ ] Flutter: Token persistence di `FlutterSecureStorage`
- [ ] Flutter: Auto-redirect berdasarkan auth state di GoRouter

---

## Phase 4 — Transaction CRUD

**Status:** Belum dimulai  
**Durasi estimasi:** 3–4 hari

Tasks:
- [ ] Backend: Verifikasi semua CRUD endpoints transactions berjalan
- [ ] Backend: Verifikasi CRUD accounts & categories
- [ ] Flutter: `AccountsNotifier`, `CategoriesNotifier`, `TransactionsNotifier` (Riverpod)
- [ ] Flutter: Layar daftar transaksi dengan pagination
- [ ] Flutter: Form tambah transaksi (pilih akun, kategori, nominal, tanggal)
- [ ] Flutter: Konfirmasi hapus transaksi
- [ ] Flutter: Filter transaksi (bulan, jenis, akun)

---

## Phase 5 — Dashboard

**Status:** Belum dimulai  
**Durasi estimasi:** 2–3 hari

Tasks:
- [ ] Backend: Verifikasi `/api/dashboard/summary` akurat
- [ ] Flutter: Kartu total saldo (kalkulasi real-time dari accounts)
- [ ] Flutter: Kartu pemasukan & pengeluaran bulan ini
- [ ] Flutter: Daftar 5 transaksi terbaru
- [ ] Flutter: Navigasi ke detail akun dan transaksi
- [ ] Flutter: Pull-to-refresh

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

