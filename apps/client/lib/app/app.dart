import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_store.dart';
import 'planning/planning_repository.dart';
import 'planning/planning_scope.dart';
import 'planning/planning_store.dart';

class OverviewApp extends StatefulWidget {
  const OverviewApp({
    this.initialRoute = AppRouter.homeRoute,
    this.repository,
    this.authRepository,
    super.key,
  });

  final String initialRoute;
  final PlanningRepository? repository;
  final AuthRepository? authRepository;

  @override
  State<OverviewApp> createState() => _OverviewAppState();
}

class _OverviewAppState extends State<OverviewApp> {
  Locale? _locale;
  late final PlanningStore _planningStore;
  late final AuthStore _authStore;

  @override
  void initState() {
    super.initState();
    _planningStore = PlanningStore(
      repository: widget.repository ?? _createDefaultRepository(),
    )..refresh();
    _authStore = AuthStore(
      repository: widget.authRepository ?? _createDefaultAuthRepository(),
    )..refresh();
  }

  PlanningRepository _createDefaultRepository() {
    const apiBaseUrl = String.fromEnvironment('OVERVIEW_API_BASE_URL');

    if (apiBaseUrl.isNotEmpty) {
      return LocalPlanningRepository(
        remoteRepository: HttpPlanningRepository(baseUrl: apiBaseUrl),
      );
    }

    return LocalPlanningRepository();
  }

  AuthRepository _createDefaultAuthRepository() {
    const apiBaseUrl = String.fromEnvironment('OVERVIEW_API_BASE_URL');

    if (apiBaseUrl.isNotEmpty) {
      return LocalAuthRepository(
        remoteRepository: HttpAuthRepository(baseUrl: apiBaseUrl),
      );
    }

    return LocalAuthRepository();
  }

  void _toggleLocale() {
    setState(() {
      final nextLanguageCode = _locale?.languageCode == 'zh' ? 'en' : 'zh';
      _locale = Locale(nextLanguageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      store: _authStore,
      child: PlanningScope(
        store: _planningStore,
        child: MaterialApp(
          title: 'Overview',
          locale: _locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          onGenerateTitle: (context) => context.l10n.appTitle,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1C6B52)),
          ),
          initialRoute: widget.initialRoute,
          onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
            settings,
            onToggleLocale: _toggleLocale,
          ),
        ),
      ),
    );
  }
}
