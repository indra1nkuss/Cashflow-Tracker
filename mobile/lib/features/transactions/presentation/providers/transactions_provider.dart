import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/transactions_repository.dart';
import '../../domain/models/transaction_model.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';

final transactionsRepositoryProvider = Provider<TransactionsRepository>((ref) {
  return TransactionsRepository();
});

class TransactionsFilterState {
  const TransactionsFilterState({
    this.type,
    this.accountId,
    this.categoryId,
  });

  final String? type;
  final String? accountId;
  final String? categoryId;

  TransactionsFilterState copyWith({
    String? type,
    String? accountId,
    String? categoryId,
    bool clearType = false,
  }) {
    return TransactionsFilterState(
      type: clearType ? null : (type ?? this.type),
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}

final transactionsFilterProvider =
    StateProvider<TransactionsFilterState>((ref) => const TransactionsFilterState());

class TransactionsNotifier extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final filter = ref.watch(transactionsFilterProvider);
    return _fetchTransactions(filter);
  }

  Future<List<TransactionModel>> _fetchTransactions(TransactionsFilterState filter) async {
    final repo = ref.read(transactionsRepositoryProvider);
    return repo.getTransactions(
      type: filter.type,
      accountId: filter.accountId,
      categoryId: filter.categoryId,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final filter = ref.read(transactionsFilterProvider);
    state = await AsyncValue.guard(() => _fetchTransactions(filter));
  }

  Future<bool> createTransaction({
    required String type,
    required double amount,
    required String description,
    required String accountId,
    required String categoryId,
    DateTime? transactionDate,
    String? notes,
  }) async {
    final repo = ref.read(transactionsRepositoryProvider);
    try {
      final newTx = await repo.createTransaction(
        type: type,
        amount: amount,
        description: description,
        accountId: accountId,
        categoryId: categoryId,
        transactionDate: transactionDate,
        notes: notes,
      );

      // Refresh transactions, accounts (for balance update), and dashboard
      state = AsyncValue.data([newTx, ...state.value ?? []]);
      ref.invalidate(dashboardNotifierProvider);
      ref.invalidate(accountsNotifierProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    final repo = ref.read(transactionsRepositoryProvider);
    try {
      await repo.deleteTransaction(id);
      state = AsyncValue.data(
        (state.value ?? []).where((t) => t.id != id).toList(),
      );
      // Invalidate balances
      ref.invalidate(dashboardNotifierProvider);
      ref.invalidate(accountsNotifierProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final transactionsNotifierProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionModel>>(() {
  return TransactionsNotifier();
});

