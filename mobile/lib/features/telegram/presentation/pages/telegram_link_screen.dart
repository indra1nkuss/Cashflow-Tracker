import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../providers/telegram_provider.dart';

class TelegramLinkScreen extends ConsumerWidget {
  const TelegramLinkScreen({super.key});

  Future<void> _confirmUnlink(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Putuskan Tautan Telegram?'),
        content: const Text(
          'Bot Telegram tidak akan dapat mencatat transaksi lagi ke akun Anda sampai ditautkan kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Putuskan'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success =
          await ref.read(telegramNotifierProvider.notifier).unlink();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Tautan Telegram berhasil diputuskan'
                : 'Gagal memutuskan tautan'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final telegramState = ref.watch(telegramNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Integrasi Telegram Bot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(telegramNotifierProvider.notifier).loadStatus(),
          ),
        ],
      ),
      body: telegramState.statusAsync.when(
        loading: () => const AppLoadingWidget(message: 'Memeriksa status tautan...'),
        error: (err, _) => AppErrorWidget(
          message: 'Gagal memuat status Telegram: $err',
          onRetry: () =>
              ref.read(telegramNotifierProvider.notifier).loadStatus(),
        ),
        data: (status) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Hero Icon & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2AABEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Telegram AI Bot',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Catat keuangan harian via chat otomatis bertenaga Groq AI',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Status Card
              if (status.isLinked)
                _buildLinkedSection(context, ref, status)
              else
                _buildUnlinkedSection(context, ref, telegramState),

              const SizedBox(height: 28),

              // Feature Explanation & Examples
              _buildUsageExamples(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLinkedSection(
    BuildContext context,
    WidgetRef ref,
    dynamic status,
  ) {
    final theme = Theme.of(context);

    return Card(
      color: const Color(0xFF16A34A).withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF16A34A), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF16A34A), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Akun Telegram Terhubung',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      if (status.telegramUsername != null)
                        Text(
                          '@${status.telegramUsername}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status.linkedAt != null)
              Text(
                'Terhubung sejak: ${DateFormatter.formatDate(status.linkedAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _confirmUnlink(context, ref),
              icon: const Icon(Icons.link_off_rounded),
              label: const Text('Putuskan Tautan'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(color: theme.colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlinkedSection(
    BuildContext context,
    WidgetRef ref,
    TelegramState state,
  ) {
    final theme = Theme.of(context);
    final activeCode = state.activeCode;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tautkan Akun Anda',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol di bawah untuk mendapatkan kode unik, lalu kirimkan ke Bot Telegram kami.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 20),

            if (activeCode != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: Column(
                  children: [
                    Text(
                      'KODE TAUTAN ANDA:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SelectableText(
                      activeCode.code,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: '/link ${activeCode.code}'),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Perintah "/link ${activeCode.code}" berhasil disalin!',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Salin Perintah Telegram'),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Buka bot di Telegram lalu ketik:\n/link ${activeCode.code}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            FilledButton.icon(
              onPressed: () async {
                final code = await ref
                    .read(telegramNotifierProvider.notifier)
                    .generateCode();
                if (context.mounted && code == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gagal membuat kode tautan')),
                  );
                }
              },
              icon: const Icon(Icons.qr_code_rounded),
              label: Text(activeCode == null
                  ? 'Dapatkan Kode Tautan'
                  : 'Buat Kode Baru'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageExamples(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CARA MENGGUNAKAN TELEGRAM BOT',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.outline,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildExampleRow(
                  '💬 Pesan Pengeluaran:',
                  '"Membeli bensin Rp50.000"',
                  '🤖 Bot mencatat EXPENSE Rp50.000 ke kategori Transportasi',
                ),
                const Divider(height: 24),
                _buildExampleRow(
                  '💬 Pesan Pemasukan:',
                  '"Diterima gaji bulanan 5 juta"',
                  '🤖 Bot mencatat INCOME Rp5.000.000 ke kategori Gaji',
                ),
                const Divider(height: 24),
                _buildExampleRow(
                  '⚠️ Pesan Belum Lengkap:',
                  '"Membeli kopi Starbucks"',
                  '🤖 Bot meminta: "Berapa nominal pengeluaran untuk kopi Starbucks?"',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExampleRow(String title, String input, String output) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(input, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        Text(output, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }
}
