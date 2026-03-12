import assert from 'node:assert/strict';

import { resolveSpeechLocale } from '../src/ai/speech-locales.js';

assert.equal(resolveSpeechLocale('zh', 'zh-CN'), 'zh-CN');
assert.equal(resolveSpeechLocale('zh-Hant', 'zh-CN'), 'zh-TW');
assert.equal(resolveSpeechLocale('en', 'zh-CN'), 'en-US');
assert.equal(resolveSpeechLocale('ja', 'zh-CN'), 'ja-JP');
assert.equal(resolveSpeechLocale('pt-BR', 'zh-CN'), 'pt-BR');
assert.equal(resolveSpeechLocale('', 'zh-CN'), 'zh-CN');

console.log('Speech locale tests passed');
