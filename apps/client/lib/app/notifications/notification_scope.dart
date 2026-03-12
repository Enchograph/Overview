import 'package:flutter/widgets.dart';

import 'notification_store.dart';

class NotificationScope extends InheritedNotifier<NotificationStore> {
  const NotificationScope({
    required NotificationStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static NotificationStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NotificationScope>();
    assert(scope != null, 'NotificationScope not found in widget tree.');
    return scope!.notifier!;
  }
}
