import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'shell/home_shell.dart';

class OverviewApp extends StatefulWidget {
  const OverviewApp({super.key});

  @override
  State<OverviewApp> createState() => _OverviewAppState();
}

class _OverviewAppState extends State<OverviewApp> {
  Locale? _locale;

  void _toggleLocale() {
    setState(() {
      final nextLanguageCode = _locale?.languageCode == 'zh' ? 'en' : 'zh';
      _locale = Locale(nextLanguageCode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      initialRoute: AppRouter.homeRoute,
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(
        settings,
        onToggleLocale: _toggleLocale,
      ),
      home: HomeShell(onToggleLocale: _toggleLocale),
    );
  }
}
