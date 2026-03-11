import 'dart:async';

import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Overview',
      'weekTab': 'Week',
      'notesTab': 'Notes',
      'captureTab': 'Capture',
      'settingsTab': 'Settings',
      'weekHeadline': 'Week at a glance',
      'weekBody': 'Weekly planning, progress snapshots, and upcoming focus areas will live here.',
      'notesHeadline': 'Notes and memos',
      'notesBody': 'Quick notes, memos, and inbox items will be grouped here for follow-up.',
      'captureHeadline': 'Add anything fast',
      'captureBody': 'Tasks, schedule entries, and notes should be capturable from one place.',
      'settingsHeadline': 'Account and sync settings',
      'settingsBody': 'Identity, sync state, and device preferences will be managed here.',
      'aiTitle': 'AI assistant',
      'aiBody': 'AI parsing and single-turn assistance will be connected here in the next phase.',
      'syncTitle': 'Sync status',
      'syncBody': 'This page will show account state, last sync time, and conflict handling entry points.',
      'syncStatusTitle': 'Local-only mode',
      'syncStatusSubtitle': 'Authentication and remote sync are not connected yet.',
      'captureShortcut': 'Go to capture',
      'aiShortcut': 'Open AI',
      'syncShortcut': 'View sync',
      'localeToggleTooltip': 'Switch language',
      'routeNotFoundTitle': 'Page not found',
      'routeNotFoundBody': 'No page is registered for: {routeName}',
    },
    'zh': {
      'appTitle': '览',
      'weekTab': '周视图',
      'notesTab': '备忘',
      'captureTab': '添加',
      'settingsTab': '设置',
      'weekHeadline': '本周总览',
      'weekBody': '周计划、进度快照和接下来的重点区域会放在这里。',
      'notesHeadline': '备忘与收件箱',
      'notesBody': '快速记录、备忘内容和待整理事项会在这里集中处理。',
      'captureHeadline': '快速添加',
      'captureBody': '任务、日程和备忘都应该能从同一个入口快速录入。',
      'settingsHeadline': '账号与同步设置',
      'settingsBody': '账号身份、同步状态和设备偏好会在这里统一管理。',
      'aiTitle': 'AI 助手',
      'aiBody': '下一阶段会在这里接入 AI 解析和单轮问答能力。',
      'syncTitle': '同步状态',
      'syncBody': '这里会展示账号状态、最近同步时间以及冲突处理入口。',
      'syncStatusTitle': '当前仅本地模式',
      'syncStatusSubtitle': '认证与远端同步尚未接通。',
      'captureShortcut': '前往添加',
      'aiShortcut': '打开 AI',
      'syncShortcut': '查看同步',
      'localeToggleTooltip': '切换语言',
      'routeNotFoundTitle': '页面不存在',
      'routeNotFoundBody': '未找到已注册页面：{routeName}',
    },
  };

  static AppLocalizations of(BuildContext context) {
    final localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations not found in context.');
    return localizations!;
  }

  String get _languageCode =>
      _localizedValues.containsKey(locale.languageCode) ? locale.languageCode : 'en';

  String _value(String key) => _localizedValues[_languageCode]![key]!;

  String get appTitle => _value('appTitle');
  String get weekTab => _value('weekTab');
  String get notesTab => _value('notesTab');
  String get captureTab => _value('captureTab');
  String get settingsTab => _value('settingsTab');
  String get weekHeadline => _value('weekHeadline');
  String get weekBody => _value('weekBody');
  String get notesHeadline => _value('notesHeadline');
  String get notesBody => _value('notesBody');
  String get captureHeadline => _value('captureHeadline');
  String get captureBody => _value('captureBody');
  String get settingsHeadline => _value('settingsHeadline');
  String get settingsBody => _value('settingsBody');
  String get aiTitle => _value('aiTitle');
  String get aiBody => _value('aiBody');
  String get syncTitle => _value('syncTitle');
  String get syncBody => _value('syncBody');
  String get syncStatusTitle => _value('syncStatusTitle');
  String get syncStatusSubtitle => _value('syncStatusSubtitle');
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
