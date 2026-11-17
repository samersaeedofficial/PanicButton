import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import 'tabs/logs_tab.dart';
import 'tabs/map_tab.dart';

class MemberHomeScreen extends StatefulWidget {
  const MemberHomeScreen({super.key});

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Member View • ${state.currentUser?.name ?? "Family"}'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: state.logout,
          ),
        ],
      ),
      body: _index == 0 ? const MapTab() : const LogsTab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on),
            label: 'Track User',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_active),
            label: 'Alerts & Audio',
          ),
        ],
      ),
    );
  }
}
