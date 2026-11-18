import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/accounts_repository.dart';
import '../../domain/models/account_model.dart';

final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  return AccountsRepository();
});

class AccountsNotifier extends AsyncNotifier<List<AccountModel>> {
  @override
  Future<List<AccountModel>> build() async {
    return _fetchAccounts();
  }

  Future<List<AccountModel>> _fetchAccounts() async {
    final repo = ref.read(accountsRepositoryProvider);
    return repo.getAccounts();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchAccounts());
  }

  /// Silently re-fetches latest accounts and balances without showing a loading spinner
  Future<void> silentRefresh() async {
    try {
      final list = await _fetchAccounts();
      state = AsyncValue.data(list);
    } catch (_) {
      // Ignored in background
    }
  }

  Future<bool> createAccount({
    required String name,
    required String accountType,
    required double initialBalance,
  }) async {
    final repo = ref.read(accountsRepositoryProvider);
    try {
      final newAccount = await repo.createAccount(
        name: name,
        accountType: accountType,
        initialBalance: initialBalance,
      );
      state = AsyncValue.data([...state.value ?? [], newAccount]);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateAccount({
    required String accountId,
    required String name,
    required String accountType,
    required double initialBalance,
  }) async {
    final repo = ref.read(accountsRepositoryProvider);
    try {
      final updated = await repo.updateAccount(
        accountId: accountId,
        name: name,
        accountType: accountType,
        initialBalance: initialBalance,
      );
      final current = state.value ?? [];
      state = AsyncValue.data(
        current.map((a) => a.id == accountId ? updated : a).toList(),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    final repo = ref.read(accountsRepositoryProvider);
    try {
      await repo.deleteAccount(accountId);
      final current = state.value ?? [];
      state = AsyncValue.data(current.where((a) => a.id != accountId).toList());
      return true;
    } catch (_) {
      return false;
    }
  }
}

final accountsNotifierProvider =
    AsyncNotifierProvider<AccountsNotifier, List<AccountModel>>(() {
  return AccountsNotifier();
});


