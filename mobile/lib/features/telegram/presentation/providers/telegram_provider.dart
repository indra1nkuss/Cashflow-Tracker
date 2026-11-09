import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/telegram_repository.dart';
import '../../domain/models/telegram_status_model.dart';

final telegramRepositoryProvider = Provider<TelegramRepository>((ref) {
  return TelegramRepository();
});

class TelegramState {
  const TelegramState({
    required this.statusAsync,
    this.activeCode,
  });

  final AsyncValue<TelegramStatusModel> statusAsync;
  final TelegramLinkCodeModel? activeCode;

  TelegramState copyWith({
    AsyncValue<TelegramStatusModel>? statusAsync,
    TelegramLinkCodeModel? activeCode,
    bool clearActiveCode = false,
  }) {
    return TelegramState(
      statusAsync: statusAsync ?? this.statusAsync,
      activeCode: clearActiveCode ? null : (activeCode ?? this.activeCode),
    );
  }
}

class TelegramNotifier extends StateNotifier<TelegramState> {
  TelegramNotifier(this._repository)
      : super(const TelegramState(statusAsync: AsyncValue.loading())) {
    loadStatus();
  }

  final TelegramRepository _repository;

  Future<void> loadStatus() async {
    state = state.copyWith(statusAsync: const AsyncValue.loading());
    try {
      final status = await _repository.getLinkStatus();
      state = state.copyWith(statusAsync: AsyncValue.data(status));
    } catch (e, st) {
      state = state.copyWith(statusAsync: AsyncValue.error(e, st));
    }
  }

  Future<TelegramLinkCodeModel?> generateCode() async {
    try {
      final code = await _repository.generateLinkCode();
      state = state.copyWith(activeCode: code);
      return code;
    } catch (e) {
      return null;
    }
  }

  Future<bool> unlink() async {
    try {
      await _repository.unlink();
      state = state.copyWith(
        clearActiveCode: true,
        statusAsync: const AsyncValue.data(
          TelegramStatusModel(isLinked: false),
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

final telegramNotifierProvider =
    StateNotifierProvider<TelegramNotifier, TelegramState>((ref) {
  final repo = ref.watch(telegramRepositoryProvider);
  return TelegramNotifier(repo);
});

