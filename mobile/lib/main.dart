import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
    await initializeDateFormatting('en_US', null);
  } catch (e) {
    debugPrint('Gagal inisialisasi locale formatting: $e');
  }
  runApp(
    const ProviderScope(
      child: PersonalFinanceTrackerApp(),
    ),
  );
}

class PersonalFinanceTrackerApp extends ConsumerWidget {
  const PersonalFinanceTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Cashflow Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

