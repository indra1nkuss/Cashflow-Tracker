# Arsitektur Sistem — Personal Finance Tracker

## Gambaran Umum

```
┌───────────────────────┐     ┌──────────────────────────┐
│   Flutter Mobile App  │     │   Telegram Bot (Webhook) │
│   (iOS / Android)     │     │   @YourBotName           │
└──────────┬────────────┘     └────────────┬─────────────┘
           │  HTTPS REST API               │  Webhook POST
           ▼                               ▼
┌──────────────────────────────────────────────────────────┐
│               Express.js Backend (Node.js + TypeScript)   │
│                                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │
│  │   Auth   │  │Transact. │  │Dashboard │  │Telegram │ │
│  │  Module  │  │  Module  │  │  Module  │  │ Module  │ │
│  └──────────┘  └──────────┘  └──────────┘  └────┬────┘ │
│                                                   │       │
│                            ┌──────────────────────▼─────┐│
│                            │       AI Parser Module      ││
│                            │   (Groq SDK — Server-side  ││
│                            │    llama-3.3-70b-versatile) ││
│                            └────────────────────────────┘│
└───────────────────────────────┬──────────────────────────┘
                                │  Prisma ORM
                                ▼
                   ┌──────────────────────────┐
                   │  Supabase (PostgreSQL)   │
                   │  - users                 │
                   │  - accounts              │
                   │  - categories            │
                   │  - transactions          │
                   │  - telegram_links        │
                   │  - telegram_messages     │
                   │  - ai_processing_logs    │
                   └──────────────────────────┘
```

---

## Layer Arsitektur Backend

### 1. Routes Layer
- File: `src/routes/index.ts`
- Bertanggung jawab mengagregasi semua module routes di bawah prefix `/api`

### 2. Controller Layer
- Menerima HTTP request, memanggil service, mengembalikan respons terstandarisasi (`ApiResponse`)
- Tidak mengandung business logic

### 3. Service Layer
- Mengandung semua business logic
- Memanggil Prisma ORM untuk operasi database
- Memanggil external services (Groq, Telegram Bot)

### 4. Middleware Layer
- `authenticateJwt` — Verifikasi JWT token
- `validateRequest` — Validasi body/query/params dengan Zod schema
- `errorHandler` — Global error handling
- `notFoundHandler` — 404 handling

---

## Layer Arsitektur Flutter (Feature-First)

```
lib/
├── core/           # Shared infrastructure
│   ├── constants/  # App constants, API routes
│   ├── errors/     # AppError class hierarchy
│   ├── network/    # Dio ApiClient + interceptors
│   ├── router/     # GoRouter configuration
│   ├── theme/      # Material 3 theme + AppColors extension
│   └── utils/      # Currency & date formatters
│
├── features/       # Feature modules (self-contained)
│   └── [feature]/
│       ├── data/        # Repository implementation, DTOs, remote data sources
│       ├── domain/      # Entities, Repository interfaces, Use Cases
│       └── presentation/
│           ├── pages/   # Screen widgets
│           ├── widgets/ # Feature-specific widgets
│           └── providers/ # Riverpod providers/notifiers
│
└── shared/         # Reusable UI components & providers
    ├── widgets/    # AppLoadingWidget, AppErrorWidget, MainScaffold
    ├── models/     # Shared data models
    └── providers/  # Shared Riverpod providers
```

---

## Alur Autentikasi

```
Flutter App
  ─► POST /api/auth/login  {email, password}
  ◄─ { token: "JWT..." }
  ─► Simpan token ke FlutterSecureStorage
  ─► Setiap request berikut: Authorization: Bearer <token>
  ─► Backend middleware verifikasi token → inject req.user
```

---

## Alur AI Transaction Parser

```
Telegram Pesan → Backend Telegram Webhook
  → TelegramService.handleWebhookUpdate()
  → AiParserService.parseTransactionMessage(text, userId)
  → GroqService.parseNaturalLanguageTransaction(text)
     → Groq API (llama-3.3-70b-versatile, JSON mode)
     → Return: { type, amount, category, description, needsClarification }
  → Jika needsClarification: kirim balik pertanyaan ke user
  → Jika lengkap: simpan Transaction ke database
  → Log ke AIProcessingLog untuk audit/debugging
```

---

## Security Considerations

| Risiko | Mitigasi |
|---|---|
| Kebocoran API key | Semua key di `.env` server-side only, tidak pernah ke Flutter |
| SQL Injection | Prisma ORM parameterized queries |
| Brute force login | Rate limiting (Phase 3 implementation) |
| Pesan Telegram duplikat | Idempotency check via `telegram_messages` (chatId + messageId UNIQUE) |
| Token expired | JWT dengan expiry 7 hari, refresh token (Phase 3) |

