import 'package:flutter/widgets.dart';

import 'speech_input_store.dart';

class SpeechInputScope extends InheritedNotifier<SpeechInputStore> {
  const SpeechInputScope({
    required SpeechInputStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static SpeechInputStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SpeechInputScope>();
    assert(scope != null, 'SpeechInputScope not found in widget tree.');
    return scope!.notifier!;
  }
}
