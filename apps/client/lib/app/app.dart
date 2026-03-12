import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'ai/ai_repository.dart';
import 'ai/ai_scope.dart';
import 'ai/ai_store.dart';
import 'ai/speech_input_scope.dart';
import 'ai/speech_input_service.dart';
import 'ai/speech_input_store.dart';
import 'app_router.dart';
import 'auth/auth_repository.dart';
import 'auth/auth_scope.dart';
import 'auth/auth_store.dart';
import 'launcher/launcher_shortcut_service.dart';
import 'notifications/notification_scope.dart';
import 'notifications/notification_service.dart';
import 'notifications/notification_store.dart';
import 'planning/planning_repository.dart';
import 'planning/planning_scope.dart';
import 'planning/planning_store.dart';

class OverviewApp extends StatefulWidget {
  const OverviewApp({
    this.initialRoute = AppRouter.homeRoute,
    this.repository,
    this.authRepository,
    this.aiRepository,
    this.speechInputService,
    this.notificationService,
    this.launcherShortcutService,
    super.key,
  });

  final String initialRoute;
  final PlanningRepository? repository;
  final AuthRepository? authRepository;
  final AiRepository? aiRepository;
  final SpeechInputService? speechInputService;
  final NotificationService? notificationService;
  final LauncherShortcutService? launcherShortcutService;

  @override
  State<OverviewApp> createState() => _OverviewAppState();
}

class _OverviewAppState extends State<OverviewApp> {
  Locale? _locale;
  late final PlanningStore _planningStore;
  late final AuthStore _authStore;
  late final AiStore _aiStore;
  late final SpeechInputStore _speechInputStore;
  late final NotificationStore _notificationStore;
  late final NotificationService _resolvedNotificationService;
  late final AuthRepository _resolvedAuthRepository;
  late final LauncherShortcutService _resolvedLauncherShortcutService;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  String? _pendingShortcutRoute;

  static const _weekShortcutType = 'shortcut_week';
  static const _captureShortcutType = 'shortcut_capture';

  @override
  void initState() {
    super.initState();
    _resolvedAuthRepository =
        widget.authRepository ?? _createDefaultAuthRepository();
    _resolvedNotificationService =
        widget.notificationService ?? FlutterNotificationService();
    _resolvedLauncherShortcutService =
        widget.launcherShortcutService ?? QuickActionsLauncherShortcutService();
    _planningStore = PlanningStore(
      repository: widget.repository ??
          _createDefaultRepository(_resolvedAuthRepository),
      notificationService: _resolvedNotificationService,
    )..refresh();
    _authStore = AuthStore(repository: _resolvedAuthRepository)..refresh();
    _aiStore = AiStore(
      repository: widget.aiRepository ??
          _createDefaultAiRepository(_resolvedAuthRepository),
    );
    _speechInputStore = SpeechInputStore(
      service: widget.speechInputService ?? AudioRecorderSpeechInputService(),
    );
    _notificationStore = NotificationStore(
      service: _resolvedNotificationService,
    )..refresh();
    _initializeLauncherShortcuts();
  }

  PlanningRepository _createDefaultRepository(AuthRepository authRepository) {
    const apiBaseUrl = String.fromEnvironment('OVERVIEW_API_BASE_URL');

    if (apiBaseUrl.isNotEmpty) {
      return LocalPlanningRepository(
        remoteRepository: HttpPlanningRepository(
          baseUrl: apiBaseUrl,
          authSessionProvider: authRepository.fetchSession,
        ),
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

  AiRepository _createDefaultAiRepository(AuthRepository authRepository) {
    const apiBaseUrl = String.fromEnvironment('OVERVIEW_API_BASE_URL');

    if (apiBaseUrl.isNotEmpty) {
      return HttpAiRepository(
        baseUrl: apiBaseUrl,
        authSessionProvider: authRepository.fetchSession,
      );
    }

    return FakeAiRepository(remoteEnabled: false);
  }

  void _toggleLocale() {
    setState(() {
      final nextLanguageCode = _locale?.languageCode == 'zh' ? 'en' : 'zh';
      _locale = Locale(nextLanguageCode);
    });
    _registerLauncherShortcuts();
  }

  Future<void> _initializeLauncherShortcuts() async {
    await _resolvedLauncherShortcutService.initialize(
      onShortcutSelected: _handleShortcutSelection,
    );
    await _registerLauncherShortcuts();
  }

  Future<void> _registerLauncherShortcuts() async {
    final l10n = AppLocalizations(_locale ?? const Locale('en'));
    await _resolvedLauncherShortcutService.setShortcutItems([
      AppLauncherShortcutItem(
        type: _weekShortcutType,
        title: l10n.shortcutsWeekLabel,
      ),
      AppLauncherShortcutItem(
        type: _captureShortcutType,
        title: l10n.shortcutsCaptureLabel,
      ),
    ]);
  }

  void _handleShortcutSelection(String shortcutType) {
    final routeName = switch (shortcutType) {
      _weekShortcutType => AppRouter.homeRoute,
      _captureShortcutType => AppRouter.captureRoute,
      _ => null,
    };
    if (routeName == null) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _pendingShortcutRoute = routeName;
      return;
    }

    _pendingShortcutRoute = null;
    navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
  }

  void _flushPendingShortcutRoute() {
    final pendingShortcutRoute = _pendingShortcutRoute;
    if (pendingShortcutRoute == null) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _pendingShortcutRoute = null;
    navigator.pushNamedAndRemoveUntil(pendingShortcutRoute, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushPendingShortcutRoute();
    });

    return AuthScope(
      store: _authStore,
      child: SpeechInputScope(
        store: _speechInputStore,
        child: NotificationScope(
          store: _notificationStore,
          child: AiScope(
            store: _aiStore,
            child: PlanningScope(
              store: _planningStore,
              child: MaterialApp(
                navigatorKey: _navigatorKey,
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
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF1C6B52),
                  ),
                ),
                initialRoute: widget.initialRoute,
                onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
                  settings,
                  onToggleLocale: _toggleLocale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
