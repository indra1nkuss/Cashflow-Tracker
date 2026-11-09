import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
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
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // User Profile Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      user != null && user.fullName.isNotEmpty
                          ? user.fullName[0].toUpperCase()
                          : 'U',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Pengguna',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '-',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Integrasi Section
          Text(
            'INTEGRASI & FITUR',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.send_rounded, color: Color(0xFF2AABEE)),
                  title: const Text('Hubungkan Telegram Bot'),
                  subtitle: const Text('Catat keuangan via pesan chat AI'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.telegramLink),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('Kelola Kategori'),
                  subtitle: const Text('Atur kategori pemasukan & pengeluaran'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.categories),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.account_balance_outlined),
                  title: const Text('Kelola Akun & Dompet'),
                  subtitle: const Text('BCA, GoPay, Tunai, dll'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push(AppRoutes.accounts),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Akun Section
          Text(
            'AKUN',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.outline,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            child: ListTile(
              leading: Icon(Icons.logout_rounded, color: theme.colorScheme.error),
              title: Text(
                'Keluar dari Akun',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _confirmLogout(context, ref),
            ),
          ),
          const SizedBox(height: 32),

          // App Version
          Center(
            child: Text(
              '$kAppName v$kAppVersion',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
