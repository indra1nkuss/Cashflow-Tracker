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

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(routerListenableProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshListenable,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authNotifierProvider);
      final location = state.matchedLocation;

      // While splash is actively initializing
      if (authState.isInitial) {
        return null;
      }

      final isAuthRoute = location == AppRoutes.login ||
          location == AppRoutes.register ||
          location == AppRoutes.splash;

      // If user is not authenticated and trying to access private page -> go to login
      if (!authState.isAuthenticated && !isAuthRoute) {
        return AppRoutes.login;
      }

      // If user is already authenticated and is on login/register/splash -> go to dashboard
      if (authState.isAuthenticated && isAuthRoute) {
        return AppRoutes.dashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.dashboard,
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.transactions,
            builder: (context, state) => const TransactionsScreen(),
          ),
          GoRoute(
            path: AppRoutes.addTransaction,
            builder: (context, state) => const AddTransactionScreen(),
          ),
          GoRoute(
            path: AppRoutes.accounts,
            builder: (context, state) => const AccountsScreen(),
          ),
          GoRoute(
            path: AppRoutes.categories,
            builder: (context, state) => const CategoriesScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.telegramLink,
            builder: (context, state) => const TelegramLinkScreen(),
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
