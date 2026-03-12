import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'routes/auth_route.dart';
import 'routes/ai_route.dart';
import 'routes/sync_route.dart';
import 'shell/home_shell.dart';

enum AppTab { week, notes, capture, settings }

class AppRouter {
  static const homeRoute = '/';
  static const weekRoute = '/week';
  static const notesRoute = '/notes';
  static const captureRoute = '/capture';
  static const settingsRoute = '/settings';
  static const aiRoute = '/ai';
  static const syncRoute = '/settings/sync';
  static const authRoute = '/settings/auth';

  static String shellRouteFor(AppTab tab) {
    switch (tab) {
      case AppTab.week:
        return homeRoute;
      case AppTab.notes:
        return notesRoute;
      case AppTab.capture:
        return captureRoute;
      case AppTab.settings:
        return settingsRoute;
    }
  }

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required VoidCallback onToggleLocale,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case homeRoute:
          case weekRoute:
            return HomeShell(
              currentTab: AppTab.week,
              onToggleLocale: onToggleLocale,
            );
          case notesRoute:
            return HomeShell(
              currentTab: AppTab.notes,
              onToggleLocale: onToggleLocale,
            );
          case captureRoute:
            return HomeShell(
              currentTab: AppTab.capture,
              onToggleLocale: onToggleLocale,
            );
          case settingsRoute:
            return HomeShell(
              currentTab: AppTab.settings,
              onToggleLocale: onToggleLocale,
            );
          case aiRoute:
            return const AiRoute();
          case syncRoute:
            return const SyncRoute();
          case authRoute:
            return const AuthRoute();
          default:
            return UnknownRoute(routeName: settings.name ?? '');
        }
      },
    );
  }
}

class UnknownRoute extends StatelessWidget {
  const UnknownRoute({required this.routeName, super.key});

  final String routeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeNotFoundTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.routeNotFoundBody(routeName),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
