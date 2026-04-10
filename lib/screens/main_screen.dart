import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dashboard/dashboard_screen.dart';
import 'alerts/alerts_screen.dart';
import 'override/override_screen.dart';
import 'history/history_screen.dart';
import 'settings/settings_screen.dart';
import '../utils/firebase_paths.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  int _unackedAlerts = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AlertsScreen(),
    OverrideScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _listenToAlerts();
  }

  void _listenToAlerts() {
    FirebaseDatabase.instance
        .ref(FirebasePaths.alertsActive)
        .onValue
        .listen((event) {
      if (!mounted) return;
      int count = 0;
      if (event.snapshot.value != null) {
        final map =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        map.forEach((key, value) {
          final alert = Map<dynamic, dynamic>.from(value);
          if (alert['acked'] == false) count++;
        });
      }
      setState(() => _unackedAlerts = count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: theme.colorScheme.surface,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: _unackedAlerts > 0
                ? Badge(
                    label: Text('$_unackedAlerts'),
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            selectedIcon: _unackedAlerts > 0
                ? Badge(
                    label: Text('$_unackedAlerts'),
                    child: const Icon(Icons.notifications),
                  )
                : const Icon(Icons.notifications),
            label: 'Alerts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Override',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}