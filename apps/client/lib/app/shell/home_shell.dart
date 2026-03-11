import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../app_router.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({required this.onToggleLocale, super.key});

  final VoidCallback onToggleLocale;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  void _openRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = <ShellTab>[
      ShellTab(
        title: l10n.weekTab,
        icon: Icons.calendar_view_week_outlined,
        content: OverviewSection(
          title: l10n.weekHeadline,
          description: l10n.weekBody,
          primaryActionLabel: l10n.captureShortcut,
          onPrimaryAction: () => setState(() => _selectedIndex = 2),
        ),
      ),
      ShellTab(
        title: l10n.notesTab,
        icon: Icons.sticky_note_2_outlined,
        content: OverviewSection(
          title: l10n.notesHeadline,
          description: l10n.notesBody,
          primaryActionLabel: l10n.aiShortcut,
          onPrimaryAction: () => _openRoute(AppRouter.aiRoute),
        ),
      ),
      ShellTab(
        title: l10n.captureTab,
        icon: Icons.add_circle_outline,
        content: OverviewSection(
          title: l10n.captureHeadline,
          description: l10n.captureBody,
          primaryActionLabel: l10n.aiShortcut,
          onPrimaryAction: () => _openRoute(AppRouter.aiRoute),
        ),
      ),
      ShellTab(
        title: l10n.settingsTab,
        icon: Icons.settings_outlined,
        content: OverviewSection(
          title: l10n.settingsHeadline,
          description: l10n.settingsBody,
          primaryActionLabel: l10n.syncShortcut,
          onPrimaryAction: () => _openRoute(AppRouter.syncRoute),
        ),
      ),
    ];
    final selectedTab = tabs[_selectedIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTab.title),
        actions: [
          IconButton(
            tooltip: l10n.localeToggleTooltip,
            onPressed: widget.onToggleLocale,
            icon: const Icon(Icons.language_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: selectedTab.content,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: tabs
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

class ShellTab {
  const ShellTab({
    required this.title,
    required this.icon,
    required this.content,
  });

  final String title;
  final IconData icon;
  final Widget content;
}

class OverviewSection extends StatelessWidget {
  const OverviewSection({
    required this.title,
    required this.description,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    super.key,
  });

  final String title;
  final String description;
  final String primaryActionLabel;
  final VoidCallback onPrimaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                description,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onPrimaryAction,
                icon: const Icon(Icons.arrow_forward_outlined),
                label: Text(primaryActionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
