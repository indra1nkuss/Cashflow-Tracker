import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, TransactionModel tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: Text('Yakin ingin menghapus transaksi "${tx.description}"?'),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(transactionsNotifierProvider.notifier)
          .deleteTransaction(tx.id);

      if (context.mounted && !success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus transaksi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final transactionsAsync = ref.watch(transactionsNotifierProvider);
    final filter = ref.watch(transactionsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Transaksi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(transactionsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua'),
                  selected: filter.type == null,
                  onSelected: (_) {
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(clearType: true),
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pengeluaran'),
                  selected: filter.type == 'EXPENSE',
                  onSelected: (selected) {
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(
                            type: selected ? 'EXPENSE' : null,
                            clearType: !selected,
                          ),
                        );
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Pemasukan'),
                  selected: filter.type == 'INCOME',
                  onSelected: (selected) {
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(
                            type: selected ? 'INCOME' : null,
                            clearType: !selected,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Transaction List Content
          Expanded(
            child: transactionsAsync.when(
              loading: () => const AppLoadingWidget(message: 'Memuat transaksi...'),
              error: (err, _) => AppErrorWidget(
                message: 'Gagal memuat transaksi: $err',
                onRetry: () =>
                    ref.read(transactionsNotifierProvider.notifier).refresh(),
              ),
              data: (transactions) {
                if (transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: theme.colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada transaksi yang cocok',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan transaksi baru untuk mulai mencatat',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.push(AppRoutes.addTransaction),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Tambah Transaksi'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(transactionsNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Card(
                        elevation: 0,
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: tx.isIncome
                                ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                                : const Color(0xFFDC2626).withValues(alpha: 0.12),
                            child: Icon(
                              tx.isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: tx.isIncome
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                          title: Text(
                            tx.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (tx.category != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceContainerHigh,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        tx.category!.name,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 6),
                                  if (tx.account != null)
                                    Text(
                                      tx.account!.name,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.outline,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                DateFormatter.formatDateTime(tx.transactionDate),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${tx.isIncome ? "+" : "-"}${CurrencyFormatter.format(tx.amount)}',
                                style: TextStyle(
                                  color: tx.isIncome
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                                ),
                                onPressed: () => _confirmDelete(context, ref, tx),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.addTransaction),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
