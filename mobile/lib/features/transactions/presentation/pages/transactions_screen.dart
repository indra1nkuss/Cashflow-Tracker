import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_error_widget.dart';
import '../../../../shared/widgets/app_loading_widget.dart';
import '../../domain/models/transaction_model.dart';
import '../providers/transactions_provider.dart';
import '../widgets/ai_transaction_dialog.dart';

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
              backgroundColor: AppTheme.primaryColor,
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
        title: const Text(
          'Daftar Transaksi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
            ),
            tooltip: 'Catat via AI',
            onPressed: () => AiTransactionDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(transactionsNotifierProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips with Smooth Sunset / Crimson theme
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua',
                  isSelected: filter.type == null,
                  onTap: () {
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(clearType: true),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pengeluaran',
                  icon: Icons.arrow_upward_rounded,
                  iconColor: const Color(0xFFEF4444),
                  isSelected: filter.type == 'EXPENSE',
                  onTap: () {
                    final isCur = filter.type == 'EXPENSE';
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(
                            type: isCur ? null : 'EXPENSE',
                            clearType: isCur,
                          ),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pemasukan',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: const Color(0xFF10B981),
                  isSelected: filter.type == 'INCOME',
                  onTap: () {
                    final isCur = filter.type == 'INCOME';
                    ref.read(transactionsFilterProvider.notifier).update(
                          (s) => s.copyWith(
                            type: isCur ? null : 'INCOME',
                            clearType: isCur,
                          ),
                        );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFFFECE5)),

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
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF1F2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long_outlined,
                              size: 40,
                              color: AppTheme.primaryColor,
                            ),
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
                              color: const Color(0xFF78716C),
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
                  color: AppTheme.primaryColor,
                  onRefresh: () =>
                      ref.read(transactionsNotifierProvider.notifier).refresh(),
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: transactions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFFECE5), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Leading Icon
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: tx.isIncome
                                    ? LinearGradient(
                                        colors: [
                                          const Color(0xFF10B981).withValues(alpha: 0.2),
                                          const Color(0xFF059669).withValues(alpha: 0.08),
                                        ],
                                      )
                                    : LinearGradient(
                                        colors: [
                                          const Color(0xFFE11D48).withValues(alpha: 0.2),
                                          const Color(0xFFEA580C).withValues(alpha: 0.08),
                                        ],
                                      ),
                              ),
                              child: Icon(
                                tx.isIncome
                                    ? Icons.arrow_downward_rounded
                                    : Icons.arrow_upward_rounded,
                                color: tx.isIncome
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE11D48),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Middle Info (Expanded to prevent any overflow)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.description,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF1C1917),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      if (tx.category != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF1F2),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: const Color(0xFFFFD4D8)),
                                          ),
                                          child: Text(
                                            tx.category!.name,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFBE123C),
                                            ),
                                          ),
                                        ),
                                      if (tx.account != null)
                                        Text(
                                          tx.account!.name,
                                          style: const TextStyle(
                                            color: Color(0xFF57534E),
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormatter.formatDateTime(tx.transactionDate),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF78716C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Trailing: Amount + Delete button (Stacked vertically)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${tx.isIncome ? "+" : "-"}${CurrencyFormatter.format(tx.amount)}',
                                  style: TextStyle(
                                    color: tx.isIncome
                                        ? const Color(0xFF059669)
                                        : const Color(0xFFE11D48),
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _confirmDelete(context, ref, tx),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F4),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: Color(0xFF78716C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: FloatingActionButton(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          onPressed: () => context.push(AppRoutes.addTransaction),
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
    Color? iconColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFFFD7CC),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : (iconColor ?? const Color(0xFF78716C)),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF44403C),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
