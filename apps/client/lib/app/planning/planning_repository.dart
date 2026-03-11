import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'planning_models.dart';

abstract class PlanningRepository {
  Future<List<ScheduleItem>> fetchSchedules();
  Future<List<TaskItem>> fetchTasks();
  Future<List<MemoItem>> fetchMemos();
  Future<void> createSchedule({required String title});
  Future<void> createTask({required String title});
  Future<void> createMemo({required String title});
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  });
}

class HttpPlanningRepository implements PlanningRepository {
  HttpPlanningRepository({
    required String baseUrl,
    HttpClient? httpClient,
  })  : _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? HttpClient();

  final Uri _baseUri;
  final HttpClient _httpClient;

  @override
  Future<List<ScheduleItem>> fetchSchedules() async {
    final payload = await _requestJson('/planning/schedules');
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<TaskItem>> fetchTasks() async {
    final payload = await _requestJson('/planning/tasks');
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MemoItem>> fetchMemos() async {
    final payload = await _requestJson('/planning/memos');
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => MemoItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> createSchedule({required String title}) async {
    final startAt = DateTime.now().toUtc();
    final endAt = startAt.add(const Duration(hours: 1));
    await _requestWithoutBody(
      'POST',
      '/planning/schedules',
      {
        'title': title,
        'startAt': startAt.toIso8601String(),
        'endAt': endAt.toIso8601String(),
        'reminders': const [],
      },
    );
  }

  @override
  Future<void> createTask({required String title}) async {
    final plannedStartAt = DateTime.now().toUtc();
    final dueAt = plannedStartAt.add(const Duration(days: 1));
    await _requestWithoutBody(
      'POST',
      '/planning/tasks',
      {
        'title': title,
        'plannedStartAt': plannedStartAt.toIso8601String(),
        'dueAt': dueAt.toIso8601String(),
        'reminders': const [],
      },
    );
  }

  @override
  Future<void> createMemo({required String title}) async {
    await _requestWithoutBody(
      'POST',
      '/planning/memos',
      {
        'title': title,
        'listId': 'inbox',
        'reminders': const [],
      },
    );
  }

  @override
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    await _requestWithoutBody(
      'PATCH',
      '/planning/memos/$memoId',
      {
        'status': archived ? 'archived' : 'active',
        'archivedAt':
            archived ? DateTime.now().toUtc().toIso8601String() : null,
      },
    );
  }

  Future<Map<String, dynamic>> _requestJson(String path) async {
    final request = await _httpClient.getUrl(_baseUri.resolve(path));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlanningRepositoryException(
        'Request failed with ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const PlanningRepositoryException('Unexpected response payload');
  }

  Future<void> _requestWithoutBody(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final request = await _httpClient.openUrl(method, _baseUri.resolve(path));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(payload));
    final response = await request.close();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.transform(utf8.decoder).join();
      throw PlanningRepositoryException(
        body.isEmpty
            ? 'Request failed with ${response.statusCode}'
            : body,
      );
    }
  }
}

class FakePlanningRepository implements PlanningRepository {
  FakePlanningRepository({
    List<ScheduleItem>? schedules,
    List<TaskItem>? tasks,
    List<MemoItem>? memos,
  })  : _schedules = List.of(schedules ?? _seedSchedules),
        _tasks = List.of(tasks ?? _seedTasks),
        _memos = List.of(memos ?? _seedMemos);

  final List<ScheduleItem> _schedules;
  final List<TaskItem> _tasks;
  final List<MemoItem> _memos;

  @override
  Future<List<ScheduleItem>> fetchSchedules() async => List.of(_schedules);

  @override
  Future<List<TaskItem>> fetchTasks() async => List.of(_tasks);

  @override
  Future<List<MemoItem>> fetchMemos() async => List.of(_memos);

  @override
  Future<void> createSchedule({required String title}) async {
    final startAt = DateTime.utc(2026, 3, 12, 9).add(
      Duration(hours: _schedules.length),
    );
    _schedules.add(
      ScheduleItem(
        id: 'schedule-${_schedules.length + 1}',
        title: title,
        startAt: startAt,
        endAt: startAt.add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<void> createTask({required String title}) async {
    final plannedStartAt = DateTime.utc(2026, 3, 12, 13).add(
      Duration(hours: _tasks.length),
    );
    _tasks.add(
      TaskItem(
        id: 'task-${_tasks.length + 1}',
        title: title,
        plannedStartAt: plannedStartAt,
        dueAt: plannedStartAt.add(const Duration(days: 1)),
      ),
    );
  }

  @override
  Future<void> createMemo({required String title}) async {
    _memos.add(
      MemoItem(
        id: 'memo-${_memos.length + 1}',
        title: title,
        listId: 'inbox',
      ),
    );
  }

  @override
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    final index = _memos.indexWhere((memo) => memo.id == memoId);
    if (index == -1) {
      throw const PlanningRepositoryException('Memo not found');
    }

    final current = _memos[index];
    _memos[index] = MemoItem(
      id: current.id,
      title: current.title,
      listId: current.listId,
      description: current.description,
      timezone: current.timezone,
      estimatedDurationMinutes: current.estimatedDurationMinutes,
      sortOrder: current.sortOrder,
      status: archived ? PlanningStatus.archived : PlanningStatus.active,
      archivedAt: archived ? DateTime.now() : null,
    );
  }
}

class PlanningRepositoryException implements Exception {
  const PlanningRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

final _seedSchedules = [
  ScheduleItem(
    id: 'schedule-1',
    title: 'Design review',
    startAt: DateTime.utc(2026, 3, 12, 9),
    endAt: DateTime.utc(2026, 3, 12, 10),
    location: 'Studio',
  ),
  ScheduleItem(
    id: 'schedule-2',
    title: 'Sprint planning',
    startAt: DateTime.utc(2026, 3, 13, 14),
    endAt: DateTime.utc(2026, 3, 13, 15),
  ),
];

final _seedTasks = [
  TaskItem(
    id: 'task-1',
    title: 'Wire planning screens',
    plannedStartAt: DateTime.utc(2026, 3, 12, 11),
    dueAt: DateTime.utc(2026, 3, 12, 17),
  ),
  TaskItem(
    id: 'task-2',
    title: 'Review API payloads',
    plannedStartAt: DateTime.utc(2026, 3, 13, 10),
    dueAt: DateTime.utc(2026, 3, 13, 18),
    status: TaskStatus.inProgress,
  ),
];

final _seedMemos = [
  MemoItem(
    id: 'memo-1',
    title: 'Ask for final icon set',
    listId: 'inbox',
  ),
  MemoItem(
    id: 'memo-2',
    title: 'Draft onboarding copy',
    listId: 'inbox',
    status: PlanningStatus.archived,
    archivedAt: DateTime.utc(2026, 3, 11, 8),
  ),
];
