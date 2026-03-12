import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../app_router.dart';
import '../pages/capture_page.dart';
import '../pages/notes_page.dart';
import '../pages/settings_page.dart';
import '../pages/week_page.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({
    required this.currentTab,
    required this.onToggleLocale,
    super.key,
  });

  final AppTab currentTab;
  final VoidCallback onToggleLocale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tabs = [
      AppTabConfig(
        tab: AppTab.week,
        title: l10n.weekTab,
        icon: Icons.calendar_view_week_outlined,
        page: WeekPage(
          onOpenCapture: () => _replaceShellRoute(context, AppTab.capture),
        ),
      ),
      AppTabConfig(
        tab: AppTab.notes,
        title: l10n.notesTab,
        icon: Icons.sticky_note_2_outlined,
        page: NotesPage(onOpenAi: () => _pushRoute(context, AppRouter.aiRoute)),
      ),
      AppTabConfig(
        tab: AppTab.capture,
        title: l10n.captureTab,
        icon: Icons.add_circle_outline,
        page: CapturePage(
          onOpenAi: () => _pushRoute(context, AppRouter.aiRoute),
        ),
      ),
      AppTabConfig(
        tab: AppTab.settings,
        title: l10n.settingsTab,
        icon: Icons.settings_outlined,
        page: SettingsPage(
          onOpenSync: () => _pushRoute(context, AppRouter.syncRoute),
          onOpenAuth: () => _pushRoute(context, AppRouter.authRoute),
        ),
      ),
    ];
    final selectedIndex = tabs.indexWhere((tab) => tab.tab == currentTab);
    final selectedTab = tabs[selectedIndex];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLayout = constraints.maxWidth >= 840;
        final isLandscapeTablet = constraints.maxWidth >= 1280;
        final showQuickAccessActions = constraints.maxWidth >= 1180;

        return Scaffold(
          appBar: AppBar(
            title: Text(selectedTab.title),
            actions: [
              if (showQuickAccessActions) ...[
                TextButton.icon(
                  onPressed: currentTab == AppTab.week
                      ? null
                      : () => _replaceShellRoute(context, AppTab.week),
                  icon: const Icon(Icons.calendar_view_week_outlined),
                  label: Text(l10n.shortcutsWeekLabel),
                ),
                TextButton.icon(
                  onPressed: currentTab == AppTab.capture
                      ? null
                      : () => _replaceShellRoute(context, AppTab.capture),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(l10n.shortcutsCaptureLabel),
                ),
              ],
              IconButton(
                tooltip: l10n.localeToggleTooltip,
                onPressed: onToggleLocale,
                icon: const Icon(Icons.language_outlined),
              ),
            ],
          ),
          body: SafeArea(
            child: isTabletLayout
                ? Row(
                    children: [
                      NavigationRail(
                        selectedIndex: selectedIndex,
                        extended: isLandscapeTablet,
                        labelType: isLandscapeTablet
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        destinations: tabs
                            .map(
                              (tab) => NavigationRailDestination(
                                icon: Icon(tab.icon),
                                label: Text(tab.title),
                              ),
                            )
                            .toList(),
                        onDestinationSelected: (index) {
                          final nextTab = tabs[index].tab;
                          if (nextTab != currentTab) {
                            _replaceShellRoute(context, nextTab);
                          }
                        },
                      ),
                      const VerticalDivider(width: 1),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1280),
                            child: _TabBody(
                                currentTab: currentTab, page: selectedTab.page),
                          ),
                        ),
                      ),
                    ],
                  )
                : _TabBody(currentTab: currentTab, page: selectedTab.page),
          ),
          bottomNavigationBar: isTabletLayout
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  destinations: tabs
                      .map(
                        (tab) => NavigationDestination(
                          icon: Icon(tab.icon),
                          label: tab.title,
                        ),
                      )
                      .toList(),
                  onDestinationSelected: (index) {
                    final nextTab = tabs[index].tab;
                    if (nextTab != currentTab) {
                      _replaceShellRoute(context, nextTab);
                    }
                  },
                ),
        );
      },
    );
  }

  void _pushRoute(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _replaceShellRoute(BuildContext context, AppTab tab) {
    Navigator.of(context).pushReplacementNamed(AppRouter.shellRouteFor(tab));
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody({
    required this.currentTab,
    required this.page,
  });

  final AppTab currentTab;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: KeyedSubtree(
        key: ValueKey(currentTab),
        child: page,
      ),
    );
  }
}

class AppTabConfig {
  const AppTabConfig({
    required this.tab,
    required this.title,
    required this.icon,
    required this.page,
  });

  final AppTab tab;
  final String title;
  final IconData icon;
  final Widget page;
}
