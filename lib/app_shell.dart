import 'package:flutter/material.dart';
import 'package:titanlog/core/theme/app_colors.dart';
import 'package:titanlog/core/utils/haptic_utils.dart';
import 'package:titanlog/features/dashboard/screens/dashboard_screen.dart';
import 'package:titanlog/features/workout/screens/workout_screen.dart';
import 'package:titanlog/features/history/screens/history_screen.dart';
import 'package:titanlog/features/analytics/screens/analytics_screen.dart';
import 'package:titanlog/features/settings/screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  final _pages = const [
    DashboardScreen(),
    WorkoutScreen(),
    HistoryScreen(),
    AnalyticsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceContainerHigh,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            HapticUtils.selectionClick();
            setState(() => _currentIndex = index);
          },
          backgroundColor: AppColors.surfaceContainer,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
          height: 65,
          labelBehavior:
              NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon:
                  Icon(Icons.dashboard, color: AppColors.primary),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.fitness_center_outlined),
              selectedIcon:
                  Icon(Icons.fitness_center, color: AppColors.primary),
              label: 'Workout',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon:
                  Icon(Icons.history, color: AppColors.primary),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon:
                  Icon(Icons.bar_chart, color: AppColors.primary),
              label: 'Analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon:
                  Icon(Icons.settings, color: AppColors.primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
