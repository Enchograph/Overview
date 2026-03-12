import 'package:flutter/widgets.dart';

import 'ai_store.dart';

class AiScope extends InheritedNotifier<AiStore> {
  const AiScope({
    required AiStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static AiStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AiScope>();
    assert(scope != null, 'AiScope not found in widget tree.');
    return scope!.notifier!;
  }
}
