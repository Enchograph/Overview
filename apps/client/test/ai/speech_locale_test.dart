import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/ai/speech_locale.dart';

void main() {
  test('resolves Chinese locale to zh-CN by default', () {
    expect(resolveSpeechLocale(const Locale('zh')), 'zh-CN');
  });

  test('preserves explicit locale variants for future i18n expansion', () {
    expect(
      resolveSpeechLocale(
        const Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW'),
      ),
      'zh-TW',
    );
    expect(
      resolveSpeechLocale(
        const Locale.fromSubtags(languageCode: 'en', countryCode: 'GB'),
      ),
      'en-GB',
    );
    expect(resolveSpeechLocale(const Locale('ja')), 'ja-JP');
  });
}
