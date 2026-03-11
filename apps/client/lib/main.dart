import 'package:flutter/material.dart';

void main() {
  runApp(const OverviewApp());
}

class OverviewApp extends StatelessWidget {
  const OverviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Overview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C6B52)),
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  static const _tabs = <({String title, IconData icon, String body})>[
    (
      title: 'Week',
      icon: Icons.calendar_view_week_outlined,
      body: 'Weekly overview will land here.',
    ),
    (
      title: 'Capture',
      icon: Icons.add_circle_outline,
      body: 'Quick capture entry points will land here.',
    ),
    (
      title: 'Settings',
      icon: Icons.settings_outlined,
      body: 'Account and sync settings will land here.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(title: Text(tab.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            tab.body,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.title,
              ),
            )
            .toList(),
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

