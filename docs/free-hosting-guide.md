# Panduan Lengkap: Hosting Backend Online 100% Gratis

Dokumen ini menjelaskan langkah demi langkah cara mempublikasikan (*deploy*) backend **Personal Finance Tracker** ke internet secara gratis menggunakan **Render.com** (atau **Koyeb**) dan menghubungkannya dengan **Supabase**, **Telegram Bot**, dan **Aplikasi Flutter Mobile**.

---

## 🏗 Arsitektur Cloud (100% Gratis)

```
┌────────────────────────┐      ┌──────────────────────────┐
│   HP Android / iOS     │      │   Telegram Bot Servers   │
│   (Aplikasi Flutter)   │      │   @Pencatatan_1nkus_bot  │
└───────────┬────────────┘      └────────────┬─────────────┘
            │ HTTPS                          │ Webhook HTTPS
            ▼                                ▼
┌──────────────────────────────────────────────────────────┐
│              Render.com / Koyeb (FREE Web Service)       │
│              https://finance-tracker-api.onrender.com    │
│              Node.js + Express + Groq AI                 │
└───────────────────────────┬──────────────────────────────┘
                            │ PostgreSQL (SSL)
                            ▼
               ┌──────────────────────────┐
               │    Supabase (FREE Tier)  │
               │    PostgreSQL Database   │
               └──────────────────────────┘
```

---

## 📋 Checklist Kredensial & Eksternal Service

Sebelum melakukan hosting, pastikan variabel berikut siap:

| Variabel | Status Saat Ini | Sumber / Cara Mendapatkan |
|---|---|---|
| `DATABASE_URL` | ✅ **SUDAH VALID** | Supabase Connection Pooler (Port 6543) |
| `DIRECT_URL` | ✅ **SUDAH VALID** | Supabase Direct Connection (Port 5432) |
| `TELEGRAM_BOT_TOKEN` | ✅ **SUDAH VALID** | `@Pencatatan_1nkus_bot` (`9267728514:...`) |
| `GROQ_API_KEY` | ⚠️ **BELUM DIISI** | Gratis di [console.groq.com/keys](https://console.groq.com/keys) |
| `JWT_SECRET` | ⚠️ **PERLU DIGANTI** | String acak rahasia minimal 32 karakter |
| `TELEGRAM_WEBHOOK_SECRET` | ⚠️ **PERLU DISIAPKAN** | String acak untuk verifikasi webhook Telegram |

---

## 🚀 LANGKAH 1: Dapatkan Groq API Key (Gratis)

1. Buka [https://console.groq.com/](https://console.groq.com/) dan login (bisa via Google).
2. Di sidebar kiri, klik menu **API Keys**.
3. Klik tombol **Create API Key**.
4. Beri nama (misal: `finance-tracker`).
5. Salin kuncinya yang berawalan `gsk_...`.
6. Simpan kunci tersebut untuk dimasukkan ke konfigurasi environment.

---

## 🚀 LANGKAH 2: Push Repository ke GitHub

Render akan membuild backend secara otomatis dari repositori GitHub Anda.

1. Buat repositori baru di [GitHub](https://github.com/new):
   - Nama repo: `personal-finance-tracker`
   - Visibility: **Private** (disarankan)
2. Buka terminal di laptop:
   ```bash
   cd C:\personal-finance-tracker
   git remote add origin https://github.com/[USERNAME-ANDA]/personal-finance-tracker.git
   git branch -M main
   git push -u origin main
   ```
   *(File `.env` otomatis tidak ikut ter-upload karena sudah ada di `.gitignore`)*.

---

## 🚀 LANGKAH 3: Deploy Backend ke Render.com (Gratis)

1. Buat akun gratis di [https://render.com/](https://render.com/) (login via GitHub).
2. Di dashboard Render, klik tombol **New +** > pilih **Web Service**.
3. Pilih **Build and deploy from a Git repository**, lalu pilih repositori `personal-finance-tracker`.
4. Isi konfigurasi berikut:
   - **Name:** `personal-finance-api` *(atau nama unik lainnya)*
   - **Region:** `Singapore (Southeast Asia)` *(paling dekat dan cepat untuk Indonesia)*
   - **Branch:** `main`
   - **Root Directory:** `backend` ⚠️ *(Wajib diisi `backend` karena ini monorepo)*
   - **Runtime:** `Node`
   - **Build Command:**
     ```bash
     npm install && npx prisma generate && npm run build
     ```
   - **Start Command:**
     ```bash
     node dist/server.js
     ```
   - **Instance Type:** Pilih **Free** ($0/month).

5. Scroll ke bawah ke bagian **Environment Variables**, klik **Add Environment Variable** dan masukkan:

   | Key | Value |
   |---|---|
   | `NODE_ENV` | `production` |
   | `PORT` | `10000` *(Render default port)* |
   | `DATABASE_URL` | Salin dari `.env` lokal Anda |
   | `DIRECT_URL` | Salin dari `.env` lokal Anda |
   | `JWT_SECRET` | String acak panjang (misal: `k3y_s3cr3t_p3rs0n4l_f1n4nc3_tr4ck3r_2026_x99`) |
   | `GROQ_API_KEY` | Masukkan API key Groq Anda (`gsk_...`) |
   | `GROQ_MODEL` | `openai/gpt-oss-20b` |
   | `TELEGRAM_BOT_TOKEN` | `9267728514:AAEkJxu5yTVx3fbHUgLbCfT5hOyHdZRB6Dc` |
   | `TELEGRAM_WEBHOOK_SECRET` | Buat string acak (misal: `wh_sec_pft_2026_xyz`) |
   | `APP_TIMEZONE` | `Asia/Jakarta` |

6. Klik tombol **Deploy Web Service**.
7. Tunggu 2-3 menit hingga statusnya menjadi **Live**.
8. Anda akan mendapatkan URL HTTPS gratis, contohnya:  
   `https://personal-finance-api-xxxx.onrender.com`
9. Uji coba dengan membuka URL tersebut di browser:  
   `https://personal-finance-api-xxxx.onrender.com/api/health`  
   Jika muncul `{"success": true, "message": "Personal Finance Tracker API is running"}`, backend Anda sudah **100% online di internet!**

---

## 🚀 LANGKAH 4: Daftarkan Webhook Telegram Bot ke Server Online

Agar bot Telegram `@Pencatatan_1nkus_bot` dapat mengirim pesan ke backend online secara real-time, daftarkan webhook sekali saja:

Gunakan terminal atau browser, jalankan URL berikut (ganti dengan URL Render dan Secret Anda):

```bash
curl -X POST "https://api.telegram.org/bot9267728514:AAEkJxu5yTVx3fbHUgLbCfT5hOyHdZRB6Dc/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://[NAMA-APP-RENDER].onrender.com/api/telegram/webhook",
    "secret_token": "[TELEGRAM_WEBHOOK_SECRET_ANDA]"
  }'
```

Jika berhasil, Telegram akan membalas:
```json
{"ok": true, "result": true, "description": "Webhook was set"}
```

Sekarang coba buka bot `@Pencatatan_1nkus_bot` di Telegram dan ketik `/start`. Bot akan langsung membalas 24 jam nonstop!

---

## 🚀 LANGKAH 5: Sambungkan Aplikasi HP Flutter ke Backend Online

Sekarang backend Anda sudah online, HP Anda bisa mengaksesnya dari mana saja (menggunakan paket data Telkomsel, Indosat, XL, atau Wi-Fi mana pun tanpa perlu satu jaringan dengan laptop).

### Build APK Production:

1. Buka terminal di folder `mobile`:
   ```bash
   cd C:\personal-finance-tracker\mobile
   ```
2. Jalankan perintah build APK dengan URL backend online:
   ```bash
   flutter build apk --release --dart-define=API_BASE_URL=https://[NAMA-APP-RENDER].onrender.com/api
   ```
3. File APK selesai di:
   ```
   C:\personal-finance-tracker\mobile\build\app\outputs\flutter-apk\app-release.apk
   ```
4. Kirim file `.apk` ke HP Anda dan install. Aplikasi sekarang terhubung langsung ke cloud!

