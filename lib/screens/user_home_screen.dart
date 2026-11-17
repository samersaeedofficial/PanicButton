import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/family_tab.dart';
import 'tabs/logs_tab.dart';
import 'tabs/map_tab.dart';
import 'tabs/settings_tab.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;

  static const List<Widget> _tabs = [
    DashboardTab(),
    MapTab(),
    LogsTab(),
    FamilyTab(),
    SettingsTab(),
  ];

  static const List<String> _titles = [
    'Emergency Hub',
    'Find My Device Map',
    'Alert History & Audio',
    'Trusted Guardians',
    'Hardware & Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final hw = state.hardwareStatus;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.sosGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
        actions: [
          // Connection status chip in header
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: hw.isConnected
                      ? AppColors.safeGreen.withValues(alpha: 0.12)
                      : Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hw.isConnected ? AppColors.safeGreen : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hw.isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_disabled_rounded,
                      size: 14,
                      color: hw.isConnected ? AppColors.safeGreenDark : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hw.isConnected ? 'ESP32' : 'OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: hw.isConnected ? AppColors.safeGreenDark : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map_rounded),
            label: 'Live Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Guardians',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Triggers',
          ),
        ],
      ),
    );
  }
}
