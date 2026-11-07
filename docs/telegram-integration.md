# Telegram Integration — Alur & Implementasi

## Gambaran Alur Lengkap

```
Pengguna Telegram                 Backend Server              Database (Supabase)
      │                                │                              │
      │  "Membeli bensin Rp50.000"     │                              │
      ├──────────────────────────────► │                              │
      │                                │                              │
      │               POST /api/telegram/webhook (Webhook dari Telegram servers)
      │                                │                              │
      │                    1. Idempotency check ──────────────────────►
      │                       (chatId + messageId sudah ada?)         │
      │                                │◄──────────────────────────── │
      │                                │  Tidak ada → lanjut          │
      │                                │                              │
      │                    2. Simpan TelegramMessage (status: PROCESSING)
      │                                ├─────────────────────────────►│
      │                                │                              │
      │                    3. Cek TelegramLink (apakah user sudah linked?)
      │                                ├─────────────────────────────►│
      │                                │◄─────────────────────────── │
      │                                │                              │
      │  [Jika belum linked]           │                              │
      │◄───────────────────────────────┤                              │
      │  "Akun belum terhubung..."     │                              │
      │                                │                              │
      │  [Jika sudah linked]           │                              │
      │                    4. AI Parse via GroqService                │
      │                       (parseNaturalLanguageTransaction)        │
      │                                │                              │
      │  [Jika needsClarification]     │                              │
      │◄───────────────────────────────┤                              │
      │  "Berapa nominalnya?"          │                              │
      │                                │                              │
      │  [Jika lengkap]                │                              │
      │                    5. Simpan Transaction ────────────────────►│
      │                    6. Update TelegramMessage (status: PROCESSED)
      │                                ├─────────────────────────────►│
      │◄───────────────────────────────┤                              │
      │  "✅ Transaksi Dicatat!"       │                              │
      │  "Rp50.000 | Transportasi"     │                              │
```

---

## Idempotency (Mencegah Pesan Ganda)

Telegram dapat mengirim webhook yang sama lebih dari sekali jika server lambat merespons.

**Mekanisme perlindungan:**
1. Tabel `telegram_messages` memiliki constraint `UNIQUE(chat_id, message_id)`
2. Setiap webhook cek terlebih dahulu: apakah `(chatId, messageId)` sudah ada?
3. Jika sudah ada → webhook diabaikan langsung tanpa memproses ulang

---

## Proses Linking Akun Telegram (Phase 6)

```
Mobile App                   Backend                    Telegram Bot
    │                           │                             │
    │  GET /telegram/link-status│                             │
    ├──────────────────────────►│                             │
    │  { isLinked: false }      │                             │
    │◄──────────────────────────│                             │
    │                           │                             │
    │  [User klik "Hubungkan"]  │                             │
    │  POST /telegram/generate-link-code                      │
    ├──────────────────────────►│                             │
    │  { code: "ABC123" }       │                             │
    │◄──────────────────────────│                             │
    │                           │                             │
    │  [Tampilkan kode ke user] │                             │
    │                           │                             │
    │                           │  User kirim /link ABC123   │
    │                           │◄────────────────────────── │
    │                           │                             │
    │                           │  Validasi code → buat TelegramLink
    │                           │                             │
    │                           │  Reply: "✅ Akun terhubung!"│
    │                           ├────────────────────────────►│
```

---

## Setup Webhook Telegram

Daftarkan webhook ke Telegram API (jalankan sekali saat deploy):

```bash
curl -X POST "https://api.telegram.org/bot<BOT_TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://your-backend-domain.com/api/telegram/webhook",
    "secret_token": "<TELEGRAM_WEBHOOK_SECRET>"
  }'
```

Backend verifikasi header `X-Telegram-Bot-Api-Secret-Token` pada setiap incoming webhook.

---

## Contoh Pesan yang Didukung

| Pesan User | Hasil Parsing AI |
|---|---|
| `"Beli bensin Rp50.000"` | EXPENSE, 50000, Transportasi |
| `"Makan siang 25rb"` | EXPENSE, 25000, Makanan & Minuman |
| `"Terima gaji 5 juta"` | INCOME, 5000000, Gaji |
| `"Transfer ke BCA 1.500.000"` | EXPENSE, 1500000, Transfer |
| `"Dapet bonus"` | Clarification: "Berapa nominal bonusnya?" |
| `"halo"` | Bukan transaksi → tidak diproses |

---

## Environment Variables yang Diperlukan

```env
TELEGRAM_BOT_TOKEN=123456789:ABCdef...     # Dari @BotFather
TELEGRAM_WEBHOOK_SECRET=random_secret_string  # Untuk verifikasi webhook
```

> ⚠️ Kedua variabel ini hanya ada di backend server. **Tidak boleh** ada di kode Flutter.

