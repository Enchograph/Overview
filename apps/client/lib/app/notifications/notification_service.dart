import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../planning/planning_models.dart';

enum NotificationPermissionStatus { unknown, granted, denied, unsupported }

class ScheduledNotification {
  const ScheduledNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });

  final int id;
  final String title;
  final String body;
  final DateTime scheduledAt;
}

abstract class NotificationService {
  Future<void> initialize();
  Future<NotificationPermissionStatus> getPermissionStatus();
  Future<NotificationPermissionStatus> requestPermission();
  Future<void> schedulePlanningReminders({
    required List<ScheduleItem> schedules,
    required List<TaskItem> tasks,
  });
  Future<void> showTestNotification();
}

class FlutterNotificationService implements NotificationService {
  FlutterNotificationService({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'overview_planning';
  static const _channelName = 'Planning reminders';
  static const _channelDescription = 'Overview planning reminders';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return NotificationPermissionStatus.unsupported;
    }

    final granted = await android.areNotificationsEnabled();
    return granted == true
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) {
      return NotificationPermissionStatus.unsupported;
    }

    final granted = await android.requestNotificationsPermission();
    return granted == true
        ? NotificationPermissionStatus.granted
        : NotificationPermissionStatus.denied;
  }

  @override
  Future<void> schedulePlanningReminders({
    required List<ScheduleItem> schedules,
    required List<TaskItem> tasks,
  }) async {
    await initialize();
    await _plugin.cancelAll();

    final upcoming = <ScheduledNotification>[
      ..._buildScheduleNotifications(schedules),
      ..._buildTaskNotifications(tasks),
    ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    for (final item in upcoming.take(8)) {
      await _plugin.zonedSchedule(
        item.id,
        item.title,
        item.body,
        tz.TZDateTime.from(item.scheduledAt.toUtc(), tz.UTC),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      999001,
      'Overview notification ready',
      'Local planning reminders are enabled on this device.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  List<ScheduledNotification> _buildScheduleNotifications(
    List<ScheduleItem> schedules,
  ) {
    final now = DateTime.now().toUtc();
    return schedules
        .where((item) => item.startAt.isAfter(now))
        .map((item) {
          final scheduledAt =
              item.startAt.subtract(const Duration(minutes: 10));
          if (!scheduledAt.isAfter(now)) {
            return null;
          }
          return ScheduledNotification(
            id: _stableId('schedule:${item.id}'),
            title: item.title,
            body: 'Schedule starts in 10 minutes.',
            scheduledAt: scheduledAt,
          );
        })
        .whereType<ScheduledNotification>()
        .toList();
  }

  List<ScheduledNotification> _buildTaskNotifications(List<TaskItem> tasks) {
    final now = DateTime.now().toUtc();
    return tasks
        .where(
            (item) => item.dueAt.isAfter(now) && item.status == TaskStatus.todo)
        .map((item) {
          final scheduledAt = item.dueAt.subtract(const Duration(minutes: 30));
          if (!scheduledAt.isAfter(now)) {
            return null;
          }
          return ScheduledNotification(
            id: _stableId('task:${item.id}'),
            title: item.title,
            body: 'Task is due in 30 minutes.',
            scheduledAt: scheduledAt,
          );
        })
        .whereType<ScheduledNotification>()
        .toList();
  }

  int _stableId(String value) {
    return value.codeUnits.fold<int>(17, (total, unit) => total * 37 + unit) &
        0x7fffffff;
  }
}

class FakeNotificationService implements NotificationService {
  FakeNotificationService({
    this.permissionStatus = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus permissionStatus;
  bool initialized = false;
  bool testNotificationShown = false;
  List<ScheduledNotification> scheduledNotifications = const [];

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<NotificationPermissionStatus> getPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    return permissionStatus;
  }

  @override
  Future<void> schedulePlanningReminders({
    required List<ScheduleItem> schedules,
    required List<TaskItem> tasks,
  }) async {
    final now = DateTime.now().toUtc();
    scheduledNotifications = [
      ...schedules.where((item) => item.startAt.isAfter(now)).map(
            (item) => ScheduledNotification(
              id: item.id.hashCode,
              title: item.title,
              body: 'Schedule starts in 10 minutes.',
              scheduledAt: item.startAt.subtract(const Duration(minutes: 10)),
            ),
          ),
      ...tasks.where((item) => item.dueAt.isAfter(now)).map(
            (item) => ScheduledNotification(
              id: item.id.hashCode,
              title: item.title,
              body: 'Task is due in 30 minutes.',
              scheduledAt: item.dueAt.subtract(const Duration(minutes: 30)),
            ),
          ),
    ];
  }

  @override
  Future<void> showTestNotification() async {
    testNotificationShown = true;
  }
}
