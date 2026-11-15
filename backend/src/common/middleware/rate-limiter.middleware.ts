import rateLimit from 'express-rate-limit';

/**
 * General API Rate Limiter
 * Allows up to 120 requests per 15 minutes per IP address.
 */
export const generalRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 120,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_REQUESTS',
      message:
        'Terlalu banyak permintaan dari alamat IP ini. Silakan coba kembali dalam 15 menit.',
    },
  },
});

/**
 * Sensitive Auth Rate Limiter (Brute-Force Protection)
 * Limits login & register attempts to 10 per 15 minutes per IP.
 */
export const authRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    error: {
      code: 'TOO_MANY_AUTH_ATTEMPTS',
      message:
        'Terlalu banyak percobaan autentikasi dari IP ini. Demi keamanan akun, silakan tunggu 15 menit sebelum mencoba kembali.',
    },
  },
});
