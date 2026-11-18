import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../providers/accounts_provider.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  void _showAddAccountSheet(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: '0');
    String accountType = 'BANK';
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tambah Akun / Dompet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Akun',
                        hintText: 'cth: BCA, GoPay, Dompet Tunai',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama akun wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: accountType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Akun',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BANK', child: Text('Bank (BCA, Mandiri, dll)')),
                        DropdownMenuItem(value: 'CASH', child: Text('Uang Tunai / Cash')),
                        DropdownMenuItem(value: 'EWALLET', child: Text('E-Wallet (GoPay, OVO, dll)')),
                        DropdownMenuItem(value: 'INVESTMENT', child: Text('Investasi / Reksadana')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Lainnya')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => accountType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Saldo awal wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isLoading = true);

                              final initial = double.tryParse(
                                      balanceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                  0.0;

                              final success = await ref
                                  .read(accountsNotifierProvider.notifier)
                                  .createAccount(
                                    name: nameCtrl.text.trim(),
                                    accountType: accountType,
                                    initialBalance: initial,
                                  );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Akun berhasil dibuat!'
                                        : 'Gagal membuat akun'),
                                  ),
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Akun'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditAccountSheet(BuildContext context, WidgetRef ref, dynamic acc) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: acc.name);
    final balanceCtrl = TextEditingController(text: acc.initialBalance.toStringAsFixed(0));
    String accountType = acc.accountType;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit Akun',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Akun',
                        hintText: 'cth: BCA, GoPay, Dompet Tunai',
                        prefixIcon: Icon(Icons.account_balance_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama akun wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: accountType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe Akun',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'BANK', child: Text('Bank (BCA, Mandiri, dll)')),
                        DropdownMenuItem(value: 'CASH', child: Text('Uang Tunai / Cash')),
                        DropdownMenuItem(value: 'EWALLET', child: Text('E-Wallet (GoPay, OVO, dll)')),
                        DropdownMenuItem(value: 'INVESTMENT', child: Text('Investasi / Reksadana')),
                        DropdownMenuItem(value: 'OTHER', child: Text('Lainnya')),
                      ],
                      onChanged: (val) {
                        if (val != null) setSheetState(() => accountType = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Saldo Awal',
                        prefixText: 'Rp ',
                        hintText: '0',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Saldo awal wajib diisi';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isLoading = true);

                              final initial = double.tryParse(
                                      balanceCtrl.text.replaceAll(RegExp(r'[^0-9.]'), '')) ??
                                  0.0;

                              final success = await ref
                                  .read(accountsNotifierProvider.notifier)
                                  .updateAccount(
                                    accountId: acc.id,
                                    name: nameCtrl.text.trim(),
                                    accountType: accountType,
                                    initialBalance: initial,
                                  );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? 'Akun berhasil diperbarui!'
                                        : 'Gagal memperbarui akun'),
                                  ),
                                );
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, dynamic acc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text(
          'Akun "${acc.name}" akan dihapus.\nRiwayat transaksi tetap tersimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await ref
          .read(accountsNotifierProvider.notifier)
          .deleteAccount(acc.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Akun berhasil dihapus' : 'Gagal menghapus akun'),
          ),
        );
      }
    }
  }

  IconData _getAccountIcon(String type) {
    switch (type) {
      case 'BANK':
        return Icons.account_balance_rounded;
      case 'CASH':
        return Icons.payments_rounded;
      case 'EWALLET':
        return Icons.phone_android_rounded;
      case 'INVESTMENT':
        return Icons.trending_up_rounded;
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Akun & Dompet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(accountsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: accountsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Memuat akun...'),
        error: (err, _) => AppErrorWidget(
          message: 'Gagal memuat akun: $err',
          onRetry: () => ref.read(accountsNotifierProvider.notifier).refresh(),
        ),
        data: (accounts) {
          final totalBalance = accounts.fold<double>(
            0.0,
            (acc, curr) => acc + curr.currentBalance,
          );

          return RefreshIndicator(
            onRefresh: () => ref.read(accountsNotifierProvider.notifier).refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Total
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total di Seluruh Akun',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.format(totalBalance),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Accounts List
                ...accounts.map(
                  (acc) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1B24) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF332D3C) : const Color(0xFFFFECE5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF331D24) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF4C2430) : const Color(0xFFFFE4E6),
                          ),
                        ),
                        child: Icon(
                          _getAccountIcon(acc.accountType),
                          color: isDark ? const Color(0xFFFB7185) : AppTheme.primaryColor,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        acc.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : const Color(0xFF1C1917),
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Tipe: ${acc.accountType} • Awal: ${CurrencyFormatter.formatCompact(acc.initialBalance)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF57534E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.format(acc.currentBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: acc.currentBalance >= 0
                                  ? (isDark ? Colors.white : const Color(0xFF1C1917))
                                  : (isDark ? const Color(0xFFF87171) : AppTheme.expenseColor),
                            ),
                          ),
                          const SizedBox(width: 4),
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 20,
                              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF78716C),
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditAccountSheet(context, ref, acc);
                              } else if (value == 'delete') {
                                _confirmDelete(context, ref, acc);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 8),
                                    Text('Edit Akun'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Hapus Akun', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: () => _showAddAccountSheet(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tambah Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
