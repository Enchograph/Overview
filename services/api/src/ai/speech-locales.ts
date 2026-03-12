const languageDefaults = new Map<string, string>([
  ['zh', 'zh-CN'],
  ['en', 'en-US'],
  ['ja', 'ja-JP'],
  ['ko', 'ko-KR'],
  ['fr', 'fr-FR'],
  ['de', 'de-DE'],
  ['es', 'es-ES'],
]);

const localeAliases = new Map<string, string>([
  ['zh', 'zh-CN'],
  ['zh-cn', 'zh-CN'],
  ['zh-hans', 'zh-CN'],
  ['zh-sg', 'zh-CN'],
  ['zh-tw', 'zh-TW'],
  ['zh-hant', 'zh-TW'],
  ['zh-hk', 'zh-HK'],
  ['en', 'en-US'],
  ['en-us', 'en-US'],
  ['en-gb', 'en-GB'],
]);

export function resolveSpeechLocale(
  locale: string | undefined,
  fallbackLocale: string,
): string {
  const normalizedInput = locale?.trim();
  if (!normalizedInput) {
    return fallbackLocale;
  }

  const alias = localeAliases.get(normalizedInput.toLowerCase());
  if (alias) {
    return alias;
  }

  const parts = normalizedInput.replace('_', '-').split('-').filter(Boolean);
  if (parts.length === 0) {
    return fallbackLocale;
  }

  const languagePart = parts[0];
  if (!languagePart) {
    return fallbackLocale;
  }

  const language = languagePart.toLowerCase();
  const region = parts.length > 1 ? parts[1]?.toUpperCase() : undefined;
  if (region) {
    return `${language}-${region}`;
  }

  return languageDefaults.get(language) ?? fallbackLocale;
}
