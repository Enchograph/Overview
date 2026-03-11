import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_strings.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  String get _languageCode =>
      localizedValues.containsKey(locale.languageCode) ? locale.languageCode : 'en';

  String _value(String key) => localizedValues[_languageCode]![key]!;

  String get appTitle => _value('appTitle');
  String get weekTab => _value('weekTab');
  String get notesTab => _value('notesTab');
  String get captureTab => _value('captureTab');
  String get settingsTab => _value('settingsTab');
  String get weekHeadline => _value('weekHeadline');
  String get weekBody => _value('weekBody');
  String get weekHighlightPlanning => _value('weekHighlightPlanning');
  String get weekHighlightProgress => _value('weekHighlightProgress');
  String get weekHighlightFocus => _value('weekHighlightFocus');
  String get notesHeadline => _value('notesHeadline');
  String get notesBody => _value('notesBody');
  String get notesHighlightInbox => _value('notesHighlightInbox');
  String get notesHighlightMemo => _value('notesHighlightMemo');
  String get notesHighlightReview => _value('notesHighlightReview');
  String get captureHeadline => _value('captureHeadline');
  String get captureBody => _value('captureBody');
  String get captureHighlightTask => _value('captureHighlightTask');
  String get captureHighlightSchedule => _value('captureHighlightSchedule');
  String get captureHighlightNote => _value('captureHighlightNote');
  String get settingsHeadline => _value('settingsHeadline');
  String get settingsBody => _value('settingsBody');
  String get settingsHighlightAccount => _value('settingsHighlightAccount');
  String get settingsHighlightSync => _value('settingsHighlightSync');
  String get settingsHighlightDevice => _value('settingsHighlightDevice');
  String get aiTitle => _value('aiTitle');
  String get aiBody => _value('aiBody');
  String get aiCta => _value('aiCta');
  String get syncTitle => _value('syncTitle');
  String get syncBody => _value('syncBody');
  String get syncStatusTitle => _value('syncStatusTitle');
  String get syncStatusSubtitle => _value('syncStatusSubtitle');
  String get syncStatusPending => _value('syncStatusPending');
  String get captureShortcut => _value('captureShortcut');
  String get aiShortcut => _value('aiShortcut');
  String get syncShortcut => _value('syncShortcut');
  String get localeToggleTooltip => _value('localeToggleTooltip');
  String get routeNotFoundTitle => _value('routeNotFoundTitle');

  String routeNotFoundBody(String routeName) =>
      _value('routeNotFoundBody').replaceFirst('{routeName}', routeName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.any(
        (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      );

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
