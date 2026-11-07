import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.child});
  final Widget child;

  static const _navItems = [
    (label: 'Dashboard', icon: Icons.home_rounded, route: AppRoutes.dashboard),
    (label: 'Transaksi', icon: Icons.receipt_long_rounded, route: AppRoutes.transactions),
    (label: 'Laporan', icon: Icons.bar_chart_rounded, route: AppRoutes.reports),
    (label: 'Pengaturan', icon: Icons.settings_rounded, route: AppRoutes.settings),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _navItems.length; i++) {
      if (location.startsWith(_navItems[i].route)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex(context),
        onDestinationSelected: (index) => context.go(_navItems[index].route),
        destinations: _navItems
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

