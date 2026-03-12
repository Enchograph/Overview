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

  String get _languageCode => localizedValues.containsKey(locale.languageCode)
      ? locale.languageCode
      : 'en';

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
  String get weekSummaryTitle => _value('weekSummaryTitle');
  String weekSummaryBody(int scheduleCount, int taskCount) => _value(
        'weekSummaryBody',
      )
          .replaceFirst('{scheduleCount}', '$scheduleCount')
          .replaceFirst('{taskCount}', '$taskCount');
  String get scheduleSectionTitle => _value('scheduleSectionTitle');
  String get scheduleEmpty => _value('scheduleEmpty');
  String get taskSectionTitle => _value('taskSectionTitle');
  String get taskEmpty => _value('taskEmpty');
  String get taskDueLabel => _value('taskDueLabel');
  String get notesHeadline => _value('notesHeadline');
  String get notesBody => _value('notesBody');
  String get notesHighlightInbox => _value('notesHighlightInbox');
  String get notesHighlightMemo => _value('notesHighlightMemo');
  String get notesHighlightReview => _value('notesHighlightReview');
  String get notesSummaryTitle => _value('notesSummaryTitle');
  String notesSummaryBody(int activeCount, int totalCount) => _value(
        'notesSummaryBody',
      )
          .replaceFirst('{activeCount}', '$activeCount')
          .replaceFirst('{totalCount}', '$totalCount');
  String get memoEmpty => _value('memoEmpty');
  String get memoArchivedLabel => _value('memoArchivedLabel');
  String get memoInboxLabel => _value('memoInboxLabel');
  String get memoArchiveAction => _value('memoArchiveAction');
  String get memoRestoreAction => _value('memoRestoreAction');
  String get captureHeadline => _value('captureHeadline');
  String get captureBody => _value('captureBody');
  String get captureHighlightTask => _value('captureHighlightTask');
  String get captureHighlightSchedule => _value('captureHighlightSchedule');
  String get captureHighlightNote => _value('captureHighlightNote');
  String get captureTypeLabel => _value('captureTypeLabel');
  String get captureTypeTask => _value('captureTypeTask');
  String get captureTypeSchedule => _value('captureTypeSchedule');
  String get captureTypeMemo => _value('captureTypeMemo');
  String get captureTitleLabel => _value('captureTitleLabel');
  String get captureTitleHint => _value('captureTitleHint');
  String get captureSubmitAction => _value('captureSubmitAction');
  String get captureSubmitting => _value('captureSubmitting');
  String get captureAiParseAction => _value('captureAiParseAction');
  String get captureAiParsing => _value('captureAiParsing');
  String get captureAiSuggestionTitle => _value('captureAiSuggestionTitle');
  String captureAiSuggestionBody(String typeLabel, String title) => _value(
        'captureAiSuggestionBody',
      )
          .replaceFirst('{typeLabel}', typeLabel)
          .replaceFirst('{title}', title);
  String captureAiConfidenceLabel(int percent) =>
      _value('captureAiConfidenceLabel').replaceFirst('{percent}', '$percent');
  String captureAiNeedsConfirm(String fields) =>
      _value('captureAiNeedsConfirm').replaceFirst('{fields}', fields);
  String get captureAiApplyAction => _value('captureAiApplyAction');
  String get captureAiDismissAction => _value('captureAiDismissAction');
  String get captureSuccess => _value('captureSuccess');
  String get captureHintTitle => _value('captureHintTitle');
  String get captureHintBody => _value('captureHintBody');
  String get settingsHeadline => _value('settingsHeadline');
  String get settingsBody => _value('settingsBody');
  String get settingsHighlightAccount => _value('settingsHighlightAccount');
  String get settingsHighlightSync => _value('settingsHighlightSync');
  String get settingsHighlightDevice => _value('settingsHighlightDevice');
  String get settingsDataSourceTitle => _value('settingsDataSourceTitle');
  String get settingsDataSourceMock => _value('settingsDataSourceMock');
  String get settingsDataSourceRemote => _value('settingsDataSourceRemote');
  String get settingsDataSummaryTitle => _value('settingsDataSummaryTitle');
  String settingsDataSummaryBody(
          int scheduleCount, int taskCount, int memoCount) =>
      _value('settingsDataSummaryBody')
          .replaceFirst('{scheduleCount}', '$scheduleCount')
          .replaceFirst('{taskCount}', '$taskCount')
          .replaceFirst('{memoCount}', '$memoCount');
  String get authTitle => _value('authTitle');
  String get authBody => _value('authBody');
  String get authEmailLabel => _value('authEmailLabel');
  String get authPasswordLabel => _value('authPasswordLabel');
  String get authLoginAction => _value('authLoginAction');
  String get authRegisterAction => _value('authRegisterAction');
  String get authLogoutAction => _value('authLogoutAction');
  String get authShortcut => _value('authShortcut');
  String get authStatusTitle => _value('authStatusTitle');
  String get authSignedOutBody => _value('authSignedOutBody');
  String authSignedInSummary(String email) =>
      _value('authSignedInSummary').replaceFirst('{email}', email);
  String authSignedInBody(String timestamp) =>
      _value('authSignedInBody').replaceFirst('{timestamp}', timestamp);
  String get authUnavailableTitle => _value('authUnavailableTitle');
  String get authUnavailableBody => _value('authUnavailableBody');
  String get authSubmitting => _value('authSubmitting');
  String get authSuccess => _value('authSuccess');
  String get aiTitle => _value('aiTitle');
  String get aiBody => _value('aiBody');
  String get aiCta => _value('aiCta');
  String get syncTitle => _value('syncTitle');
  String get syncBody => _value('syncBody');
  String get syncStatusTitle => _value('syncStatusTitle');
  String get syncStatusSubtitle => _value('syncStatusSubtitle');
  String get syncStatusPending => _value('syncStatusPending');
  String get syncRemoteEnabled => _value('syncRemoteEnabled');
  String get syncRemoteDisabled => _value('syncRemoteDisabled');
  String get syncPendingTitle => _value('syncPendingTitle');
  String syncPendingBody(int operationCount, int itemCount) =>
      _value('syncPendingBody')
          .replaceFirst('{operationCount}', '$operationCount')
          .replaceFirst('{itemCount}', '$itemCount');
  String get syncConflictTitle => _value('syncConflictTitle');
  String syncConflictBody(int itemCount) =>
      _value('syncConflictBody').replaceFirst('{itemCount}', '$itemCount');
  String get syncLastAttemptLabel => _value('syncLastAttemptLabel');
  String get syncLastSuccessLabel => _value('syncLastSuccessLabel');
  String get syncLastErrorLabel => _value('syncLastErrorLabel');
  String get syncConflictLabel => _value('syncConflictLabel');
  String get syncPhaseIdle => _value('syncPhaseIdle');
  String get syncPhaseSyncing => _value('syncPhaseSyncing');
  String get syncPhaseSuccess => _value('syncPhaseSuccess');
  String get syncPhaseBlocked => _value('syncPhaseBlocked');
  String get syncPhaseFailed => _value('syncPhaseFailed');
  String get syncRunAction => _value('syncRunAction');
  String get captureShortcut => _value('captureShortcut');
  String get aiShortcut => _value('aiShortcut');
  String get syncShortcut => _value('syncShortcut');
  String get retryAction => _value('retryAction');
  String get dataStatusIdle => _value('dataStatusIdle');
  String dataStatusUpdated(String timestamp) =>
      _value('dataStatusUpdated').replaceFirst('{timestamp}', timestamp);
  String get localeToggleTooltip => _value('localeToggleTooltip');
  String get routeNotFoundTitle => _value('routeNotFoundTitle');

  String routeNotFoundBody(String routeName) =>
      _value('routeNotFoundBody').replaceFirst('{routeName}', routeName);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
        (supportedLocale) =>
            supportedLocale.languageCode == locale.languageCode,
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
