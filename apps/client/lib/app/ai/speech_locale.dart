import 'package:flutter/widgets.dart';

const Map<String, String> _speechLanguageDefaults = {
  'zh': 'zh-CN',
  'en': 'en-US',
  'ja': 'ja-JP',
  'ko': 'ko-KR',
  'fr': 'fr-FR',
  'de': 'de-DE',
  'es': 'es-ES',
};

String resolveSpeechLocale(Locale locale) {
  final language = locale.languageCode.trim().toLowerCase();
  final country = locale.countryCode?.trim().toUpperCase();
  if (language.isEmpty) {
    return 'zh-CN';
  }

  final combined = country == null || country.isEmpty
      ? language
      : '$language-$country';

  switch (combined) {
    case 'zh':
    case 'zh-CN':
      return 'zh-CN';
    case 'zh-TW':
      return 'zh-TW';
    case 'zh-HK':
      return 'zh-HK';
    case 'en':
      return 'en-US';
  }

  if (country != null && country.isNotEmpty) {
    return '$language-$country';
  }

  return _speechLanguageDefaults[language] ?? 'en-US';
}
