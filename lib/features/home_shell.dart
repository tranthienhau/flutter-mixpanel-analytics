import 'package:flutter/material.dart';

import 'gamification/gamification_dashboard_screen.dart';
import 'shopping/product_list_screen.dart';

/// Root shell with bottom navigation between the shopping funnel and the
/// gamification dashboard. Each tab is a screen that emits typed Mixpanel
/// events as the user moves through the browse -> purchase funnel and the
/// XP / streak / badge engagement loop.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _tabs = [
    ProductListScreen(),
    GamificationDashboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Progress',
          ),
        ],
      ),
    );
  }
}
