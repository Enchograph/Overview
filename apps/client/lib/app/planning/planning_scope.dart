import 'package:flutter/widgets.dart';

import 'planning_store.dart';

class PlanningScope extends InheritedNotifier<PlanningStore> {
  const PlanningScope({
    required PlanningStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static PlanningStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PlanningScope>();
    assert(scope != null, 'PlanningScope not found in widget tree.');
    return scope!.notifier!;
  }
}
