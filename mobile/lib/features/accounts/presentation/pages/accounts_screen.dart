import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHigh,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total di Seluruh Akun',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          CurrencyFormatter.format(totalBalance),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Accounts List
                ...accounts.map(
                  (acc) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    elevation: 0,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.primaryContainer,
                        child: Icon(
                          _getAccountIcon(acc.accountType),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        acc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Tipe: ${acc.accountType} • Awal: ${CurrencyFormatter.formatCompact(acc.initialBalance)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      trailing: Text(
                        CurrencyFormatter.format(acc.currentBalance),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: acc.currentBalance >= 0
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAccountSheet(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Tambah Akun'),
      ),
    );
  }
}
