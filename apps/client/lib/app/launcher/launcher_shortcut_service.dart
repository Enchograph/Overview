import 'package:quick_actions/quick_actions.dart';

class AppLauncherShortcutItem {
  const AppLauncherShortcutItem({
    required this.type,
    required this.title,
    this.subtitle,
    this.icon,
  });

  final String type;
  final String title;
  final String? subtitle;
  final String? icon;
}

abstract class LauncherShortcutService {
  Future<void> initialize({
    required void Function(String shortcutType) onShortcutSelected,
  });

  Future<void> setShortcutItems(List<AppLauncherShortcutItem> items);
}

class QuickActionsLauncherShortcutService implements LauncherShortcutService {
  QuickActionsLauncherShortcutService({
    QuickActions? quickActions,
  }) : _quickActions = quickActions ?? const QuickActions();

  final QuickActions _quickActions;

  @override
  Future<void> initialize({
    required void Function(String shortcutType) onShortcutSelected,
  }) {
    return _quickActions.initialize(onShortcutSelected);
  }

  @override
  Future<void> setShortcutItems(List<AppLauncherShortcutItem> items) {
    return _quickActions.setShortcutItems(
      items
          .map(
            (item) => ShortcutItem(
              type: item.type,
              localizedTitle: item.title,
              localizedSubtitle: item.subtitle,
              icon: item.icon,
            ),
          )
          .toList(),
    );
  }
}

class FakeLauncherShortcutService implements LauncherShortcutService {
  void Function(String shortcutType)? _handler;
  List<AppLauncherShortcutItem> items = const [];

  @override
  Future<void> initialize({
    required void Function(String shortcutType) onShortcutSelected,
  }) async {
    _handler = onShortcutSelected;
  }

  @override
  Future<void> setShortcutItems(List<AppLauncherShortcutItem> items) async {
    this.items = List.of(items);
  }

  void trigger(String shortcutType) {
    _handler?.call(shortcutType);
  }
}
