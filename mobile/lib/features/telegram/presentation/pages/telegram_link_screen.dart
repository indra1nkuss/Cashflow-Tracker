import 'package:flutter/material.dart';

/// Telegram Link Screen — Placeholder for Phase 6 (Telegram Integration)
class TelegramLinkScreen extends StatelessWidget {
  const TelegramLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungkan Telegram')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.send_rounded,
              size: 72,
              color: const Color(0xFF2AABEE), // Telegram brand color
            ),
            const SizedBox(height: 20),
            Text(
              'Hubungkan Telegram Bot',
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Catat pengeluaran dan pemasukan langsung dari Telegram Bot kami dengan bantuan AI.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Text(
                '⚠️ Fitur ini akan diimplementasikan pada Phase 6 (Telegram Integration).\nFungsionalitas: scan QR code atau kode tautan untuk menghubungkan akun Telegram Anda.',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

