import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/bubble_background.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    final currentMode = ref.read(themeModeProvider);

    Widget buildOption({
      required String title,
      required IconData icon,
      required Color iconColor,
      required ThemeMode mode,
      required BuildContext ctx,
    }) {
      final isSelected = currentMode == mode;
      return ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor)
            : null,
        onTap: () {
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
          Navigator.pop(ctx);
        },
      );
    }

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Pilih Tema Tampilan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildOption(
              title: 'Mode Terang (Light)',
              icon: Icons.wb_sunny_rounded,
              iconColor: const Color(0xFFF59E0B),
              mode: ThemeMode.light,
              ctx: ctx,
            ),
            buildOption(
              title: 'Mode Gelap (Dark)',
              icon: Icons.nightlight_round,
              iconColor: const Color(0xFFFB7185),
              mode: ThemeMode.dark,
              ctx: ctx,
            ),
            buildOption(
              title: 'Ikuti Pengaturan Sistem HP',
              icon: Icons.settings_system_daydream_rounded,
              iconColor: const Color(0xFF6B7280),
              mode: ThemeMode.system,
              ctx: ctx,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    final isDark = theme.brightness == Brightness.dark;
    final currentThemeMode = ref.watch(themeModeProvider);
    final themeModeLabel = currentThemeMode == ThemeMode.light
        ? 'Mode Terang (Light)'
        : currentThemeMode == ThemeMode.dark
            ? 'Mode Gelap (Dark)'
            : 'Ikuti Sistem HP';

    final colors = AppTheme.colorsOf(context);
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final initial = user != null && user.fullName.isNotEmpty
        ? user.fullName[0].toUpperCase()
        : 'U';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // === Gradient Header ===
          SliverToBoxAdapter(
            child: Container(
              decoration: BoxDecoration(
                gradient: colors.sunsetGradient,
              ),
              child: SafeArea(
                bottom: false,
                child: ClipRect(
                  child: Stack(
                    children: [
                      const AmbientBubbles(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        child: Column(
                          children: [
                            // AppBar row
                            Row(
                              children: [
                                const Text(
                                  'Pengaturan',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            // Profile row
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.5),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24,
                                      ),
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? '-',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.3)),
                                  ),
                                  child: const Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // === Content ===
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Section: Integrasi & Fitur
                _buildSectionLabel('INTEGRASI & FITUR', theme, colors),
                const SizedBox(height: 10),
                _buildCard([
                  _buildListTile(
                    icon: Icons.send_rounded,
                    iconColor: const Color(0xFF2AABEE),
                    title: 'Hubungkan Telegram Bot',
                    subtitle: 'Catat keuangan via pesan chat AI',
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.telegramLink),
                  ),
                  _buildDivider(isDark: isDark),
                  _buildListTile(
                    icon: Icons.category_rounded,
                    iconColor: const Color(0xFFEA580C),
                    title: 'Kelola Kategori',
                    subtitle: 'Atur kategori pemasukan & pengeluaran',
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.categories),
                  ),
                  _buildDivider(isDark: isDark),
                  _buildListTile(
                    icon: Icons.account_balance_rounded,
                    iconColor: const Color(0xFFE11D48),
                    title: 'Kelola Akun & Dompet',
                    subtitle: 'BCA, GoPay, Tunai, dll',
                    isDark: isDark,
                    onTap: () => context.push(AppRoutes.accounts),
                  ),
                ], isDark: isDark),
                const SizedBox(height: 24),

                // Section: Tampilan & Tema
                _buildSectionLabel('TAMPILAN & TEMA', theme, colors),
                const SizedBox(height: 10),
                _buildCard([
                  _buildListTile(
                    icon: isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Tema Tampilan',
                    subtitle: themeModeLabel,
                    isDark: isDark,
                    onTap: () => _showThemeDialog(context, ref),
                  ),
                ], isDark: isDark),
                const SizedBox(height: 24),

                // Section: Akun
                _buildSectionLabel('AKUN', theme, colors),
                const SizedBox(height: 10),
                _buildCard([
                  _buildListTile(
                    icon: Icons.logout_rounded,
                    iconColor: theme.colorScheme.error,
                    title: 'Keluar dari Akun',
                    subtitle: 'Anda akan dikembalikan ke halaman login',
                    titleColor: theme.colorScheme.error,
                    isDark: isDark,
                    onTap: () => _confirmLogout(context, ref),
                    showChevron: false,
                  ),
                ], isDark: isDark),
                const SizedBox(height: 32),

                // App Version
                Center(
                  child: Text(
                    '$kAppName v$kAppVersion',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF78716C),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label, ThemeData theme, AppColors colors) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            gradient: colors.primaryGradient,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: const Color(0xFFE11D48),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children, {bool isDark = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B24) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider({bool isDark = false}) => Divider(
        height: 1,
        indent: 56,
        endIndent: 16,
        color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
      );

  Widget _buildListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDark = false,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: isDark ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF1C1917)),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF57534E),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF78716C),
            )
          : null,
      onTap: onTap,
    );
  }
}
