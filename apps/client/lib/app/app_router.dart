import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'routes/ai_route.dart';
import 'routes/sync_route.dart';
import 'shell/home_shell.dart';

class AppRouter {
  static const homeRoute = '/';
  static const aiRoute = '/ai';
  static const syncRoute = '/settings/sync';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings, {
    required VoidCallback onToggleLocale,
  }) {
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) {
        switch (settings.name) {
          case homeRoute:
            return HomeShell(onToggleLocale: onToggleLocale);
          case aiRoute:
            return const AiRoute();
          case syncRoute:
            return const SyncRoute();
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
