import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/authentication/presentation/providers/auth_provider.dart';
import '../../features/authentication/presentation/pages/splash_screen.dart';
import '../../features/authentication/presentation/pages/login_screen.dart';
import '../../features/authentication/presentation/pages/register_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/transactions/presentation/pages/transactions_screen.dart';
import '../../features/transactions/presentation/pages/add_transaction_screen.dart';
import '../../features/accounts/presentation/pages/accounts_screen.dart';
import '../../features/categories/presentation/pages/categories_screen.dart';
import '../../features/reports/presentation/pages/reports_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/telegram/presentation/pages/telegram_link_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String addTransaction = '/transactions/add';
  static const String accounts = '/accounts';
  static const String categories = '/categories';
  static const String reports = '/reports';
  static const String settings = '/settings';
  static const String telegramLink = '/telegram-link';
}

class RouterListenable extends ChangeNotifier {
  RouterListenable(Ref ref) {
    ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerListenableProvider = Provider<RouterListenable>((ref) {
  return RouterListenable(ref);
});

CustomTransitionPage<void> _buildSmoothPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      final slideAnim = Tween<Offset>(
        begin: const Offset(0.0, 0.04),
        end: Offset.zero,
      ).animate(curvedAnimation);

      return FadeTransition(
        opacity: curvedAnimation,
        child: SlideTransition(
          position: slideAnim,
          child: child,
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // While splash screen is checking initial auth state, stay on splash
      if (authState.isInitial || authState.isLoading) {
        return null;
      }

      final isSplash = location == AppRoutes.splash;
      final isAuthForm = location == AppRoutes.login || location == AppRoutes.register;

      // If user is not authenticated:
      // Redirect to login if on splash or any private page
      if (!authState.isAuthenticated) {
        if (isSplash || !isAuthForm) {
          return AppRoutes.login;
        }
        return null;
      }

      // If user is already authenticated:
      // Redirect to dashboard if on splash, login, or register
      if (authState.isAuthenticated && (isSplash || isAuthForm)) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _buildSmoothPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _buildSmoothPage(
          key: state.pageKey,
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => _buildSmoothPage(
          key: state.pageKey,
          child: const RegisterScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const TransactionsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.addTransaction,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const AddTransactionScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const AccountsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.categories,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const CategoriesScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.reports,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const ReportsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.settings,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const SettingsScreen(),
            ),
          ),
          GoRoute(
            path: AppRoutes.telegramLink,
            pageBuilder: (context, state) => _buildSmoothPage(
              key: state.pageKey,
              child: const TelegramLinkScreen(),
            ),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Halaman tidak ditemukan: ${state.error}'),
      ),
    ),
  );
});
