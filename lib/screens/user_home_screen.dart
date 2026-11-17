import 'package:flutter/material.dart';
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
    'PanicButton',
    'Live Map',
    'Alert Logs',
    'Family Members',
    'Settings & Actions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        centerTitle: false,
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Logs',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group),
            label: 'Family',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
