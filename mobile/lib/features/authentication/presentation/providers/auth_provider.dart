import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/app_error.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authRepository) : super(AuthState.initial());

  final AuthRepository _authRepository;

  Future<void> checkAuthStatus() async {
    state = AuthState.loading();
    try {
      final token = await _authRepository.getToken();
      if (token == null || token.isEmpty) {
        state = AuthState.unauthenticated();
        return;
      }

      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user: user, token: token);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = AuthState.loading();
    try {
      final result = await _authRepository.login(
        email: email,
        password: password,
      );
      state = AuthState.authenticated(user: result.user, token: result.token);
      return true;
    } on AppError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Terjadi kesalahan yang tidak diketahui');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = AuthState.loading();
    try {
      final result = await _authRepository.register(
        email: email,
        password: password,
        fullName: fullName,
      );
      state = AuthState.authenticated(user: result.user, token: result.token);
      return true;
    } on AppError catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (e) {
      state = AuthState.error('Terjadi kesalahan yang tidak diketahui');
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AuthState.unauthenticated();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
