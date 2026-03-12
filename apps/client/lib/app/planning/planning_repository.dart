import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_repository.dart';
import 'planning_models.dart';

abstract class PlanningRepository {
  Future<List<ScheduleItem>> fetchSchedules();
  Future<List<TaskItem>> fetchTasks();
  Future<List<MemoItem>> fetchMemos();
  Future<void> createSchedule({
    required String title,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    int? durationMinutes,
  });
  Future<void> createTask({
    required String title,
    DateTime? plannedStartAt,
    DateTime? dueAt,
    String? location,
    int? plannedDurationMinutes,
  });
  Future<void> createMemo({
    required String title,
    String? listId,
    int? estimatedDurationMinutes,
  });
  Future<void> updateScheduleTitle({
    required String scheduleId,
    required String title,
  });
  Future<void> updateTaskTitle({
    required String taskId,
    required String title,
  });
  Future<void> updateMemoTitle({
    required String memoId,
    required String title,
  });
  Future<void> deleteSchedule({required String scheduleId});
  Future<void> deleteTask({required String taskId});
  Future<void> deleteMemo({required String memoId});
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  });
  Future<PlanningSyncStatus> fetchSyncStatus();
  Future<PlanningSyncStatus> runSync();
}

abstract class PlanningSyncRemote {
  Future<List<ScheduleItem>> fetchSchedules();
  Future<List<TaskItem>> fetchTasks();
  Future<List<MemoItem>> fetchMemos();
  Future<ScheduleItem> pushSchedule(ScheduleItem item);
  Future<ScheduleItem> updateSchedule(ScheduleItem item);
  Future<void> deleteSchedule({required String scheduleId});
  Future<TaskItem> pushTask(TaskItem item);
  Future<TaskItem> updateTask(TaskItem item);
  Future<void> deleteTask({required String taskId});
  Future<MemoItem> pushMemo(MemoItem item);
  Future<MemoItem> updateMemo(MemoItem item);
  Future<void> deleteMemo({required String memoId});
  Future<MemoItem> pushMemoArchive(MemoItem item);
}

class HttpPlanningRepository implements PlanningRepository, PlanningSyncRemote {
  HttpPlanningRepository({
    required String baseUrl,
    HttpClient? httpClient,
    Future<AuthSession?> Function()? authSessionProvider,
  })  : _baseUri = Uri.parse(baseUrl),
        _httpClient = httpClient ?? HttpClient(),
        _authSessionProvider = authSessionProvider;

  final Uri _baseUri;
  final HttpClient _httpClient;
  final Future<AuthSession?> Function()? _authSessionProvider;

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
  Future<void> createSchedule({
    required String title,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    int? durationMinutes,
  }) async {
    final resolvedStartAt = startAt ?? DateTime.now().toUtc();
    await pushSchedule(
      ScheduleItem(
        id: 'local',
        title: title,
        startAt: resolvedStartAt,
        endAt: endAt ?? resolvedStartAt.add(const Duration(hours: 1)),
        location: location,
        durationMinutes: durationMinutes,
      ),
    );
  }

  @override
  Future<void> createTask({
    required String title,
    DateTime? plannedStartAt,
    DateTime? dueAt,
    String? location,
    int? plannedDurationMinutes,
  }) async {
    final resolvedStartAt = plannedStartAt ?? DateTime.now().toUtc();
    await pushTask(
      TaskItem(
        id: 'local',
        title: title,
        plannedStartAt: resolvedStartAt,
        dueAt: dueAt ?? resolvedStartAt.add(const Duration(days: 1)),
        location: location,
        plannedDurationMinutes: plannedDurationMinutes,
      ),
    );
  }

  @override
  Future<void> createMemo({
    required String title,
    String? listId,
    int? estimatedDurationMinutes,
  }) async {
    await pushMemo(
      MemoItem(
        id: 'local',
        title: title,
        listId: listId ?? 'inbox',
        estimatedDurationMinutes: estimatedDurationMinutes,
      ),
    );
  }

  @override
  Future<void> updateScheduleTitle({
    required String scheduleId,
    required String title,
  }) async {
    final current = await _requestJson('/planning/schedules/$scheduleId');
    await updateSchedule(
      ScheduleItem(
        id: current['id'] as String,
        title: title,
        startAt: DateTime.parse(current['startAt'] as String),
        endAt: current['endAt'] == null
            ? null
            : DateTime.parse(current['endAt'] as String),
        description: current['description'] as String?,
        location: current['location'] as String?,
        timezone: current['timezone'] as String?,
        durationMinutes: current['durationMinutes'] as int?,
        status: parsePlanningStatus(current['status'] as String?),
        syncState: parseSyncState(current['syncState'] as String?),
      ),
    );
  }

  @override
  Future<void> updateTaskTitle({
    required String taskId,
    required String title,
  }) async {
    final current = await _requestJson('/planning/tasks/$taskId');
    await updateTask(
      TaskItem(
        id: current['id'] as String,
        title: title,
        plannedStartAt: DateTime.parse(current['plannedStartAt'] as String),
        dueAt: DateTime.parse(current['dueAt'] as String),
        plannedEndAt: current['plannedEndAt'] == null
            ? null
            : DateTime.parse(current['plannedEndAt'] as String),
        description: current['description'] as String?,
        location: current['location'] as String?,
        timezone: current['timezone'] as String?,
        plannedDurationMinutes: current['plannedDurationMinutes'] as int?,
        status: parseTaskStatus(current['status'] as String?),
        completionAt: current['completionAt'] == null
            ? null
            : DateTime.parse(current['completionAt'] as String),
        syncState: parseSyncState(current['syncState'] as String?),
      ),
    );
  }

  @override
  Future<void> updateMemoTitle({
    required String memoId,
    required String title,
  }) async {
    final current = await _requestJson('/planning/memos/$memoId');
    await updateMemo(
      MemoItem(
        id: current['id'] as String,
        title: title,
        listId: current['listId'] as String,
        description: current['description'] as String?,
        timezone: current['timezone'] as String?,
        estimatedDurationMinutes: current['estimatedDurationMinutes'] as int?,
        sortOrder: current['sortOrder'] as int?,
        status: parsePlanningStatus(current['status'] as String?),
        archivedAt: current['archivedAt'] == null
            ? null
            : DateTime.parse(current['archivedAt'] as String),
        syncState: parseSyncState(current['syncState'] as String?),
      ),
    );
  }

  @override
  Future<void> deleteSchedule({required String scheduleId}) async {
    await _requestEmpty('DELETE', '/planning/schedules/$scheduleId');
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    await _requestEmpty('DELETE', '/planning/tasks/$taskId');
  }

  @override
  Future<void> deleteMemo({required String memoId}) async {
    await _requestEmpty('DELETE', '/planning/memos/$memoId');
  }

  @override
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    await pushMemoArchive(
      MemoItem(
        id: memoId,
        title: '',
        listId: 'inbox',
        status: archived ? PlanningStatus.archived : PlanningStatus.active,
        archivedAt: archived ? DateTime.now().toUtc() : null,
      ),
    );
  }

  @override
  Future<PlanningSyncStatus> fetchSyncStatus() async {
    return const PlanningSyncStatus(
      phase: PlanningSyncPhase.success,
      isRemoteEnabled: true,
      pendingOperationCount: 0,
      pendingItemCount: 0,
      conflictItemCount: 0,
    );
  }

  @override
  Future<PlanningSyncStatus> runSync() async {
    return PlanningSyncStatus(
      phase: PlanningSyncPhase.success,
      isRemoteEnabled: true,
      pendingOperationCount: 0,
      pendingItemCount: 0,
      conflictItemCount: 0,
      lastAttemptAt: DateTime.now().toUtc(),
      lastSuccessAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<ScheduleItem> pushSchedule(ScheduleItem item) async {
    final created = await _requestItem(
      'POST',
      '/planning/schedules',
      {
        'title': item.title,
        'startAt': item.startAt.toIso8601String(),
        'endAt': item.endAt?.toIso8601String(),
        'description': item.description,
        'location': item.location,
        'timezone': item.timezone,
        'durationMinutes': item.durationMinutes,
        'reminders': const [],
      },
    );
    return ScheduleItem.fromJson(created);
  }

  @override
  Future<ScheduleItem> updateSchedule(ScheduleItem item) async {
    final updated = await _requestItem(
      'PATCH',
      '/planning/schedules/${item.id}',
      {
        'title': item.title,
        'startAt': item.startAt.toIso8601String(),
        'endAt': item.endAt?.toIso8601String(),
        'description': item.description,
        'location': item.location,
        'timezone': item.timezone,
        'durationMinutes': item.durationMinutes,
        'status': planningStatusApiValue(item.status),
      },
    );
    return ScheduleItem.fromJson(updated);
  }

  @override
  Future<TaskItem> pushTask(TaskItem item) async {
    final created = await _requestItem(
      'POST',
      '/planning/tasks',
      {
        'title': item.title,
        'plannedStartAt': item.plannedStartAt.toIso8601String(),
        'dueAt': item.dueAt.toIso8601String(),
        'plannedEndAt': item.plannedEndAt?.toIso8601String(),
        'description': item.description,
        'location': item.location,
        'timezone': item.timezone,
        'plannedDurationMinutes': item.plannedDurationMinutes,
        'reminders': const [],
      },
    );
    return TaskItem.fromJson(created);
  }

  @override
  Future<TaskItem> updateTask(TaskItem item) async {
    final updated = await _requestItem(
      'PATCH',
      '/planning/tasks/${item.id}',
      {
        'title': item.title,
        'plannedStartAt': item.plannedStartAt.toIso8601String(),
        'dueAt': item.dueAt.toIso8601String(),
        'plannedEndAt': item.plannedEndAt?.toIso8601String(),
        'description': item.description,
        'location': item.location,
        'timezone': item.timezone,
        'plannedDurationMinutes': item.plannedDurationMinutes,
        'status': taskStatusApiValue(item.status),
        'completionAt': item.completionAt?.toIso8601String(),
      },
    );
    return TaskItem.fromJson(updated);
  }

  @override
  Future<MemoItem> pushMemo(MemoItem item) async {
    final created = await _requestItem(
      'POST',
      '/planning/memos',
      {
        'title': item.title,
        'listId': item.listId,
        'description': item.description,
        'timezone': item.timezone,
        'estimatedDurationMinutes': item.estimatedDurationMinutes,
        'sortOrder': item.sortOrder,
        'reminders': const [],
      },
    );
    return MemoItem.fromJson(created);
  }

  @override
  Future<MemoItem> updateMemo(MemoItem item) async {
    final updated = await _requestItem(
      'PATCH',
      '/planning/memos/${item.id}',
      {
        'title': item.title,
        'listId': item.listId,
        'description': item.description,
        'timezone': item.timezone,
        'estimatedDurationMinutes': item.estimatedDurationMinutes,
        'sortOrder': item.sortOrder,
        'status': planningStatusApiValue(item.status),
        'archivedAt': item.archivedAt?.toIso8601String(),
      },
    );
    return MemoItem.fromJson(updated);
  }

  @override
  Future<MemoItem> pushMemoArchive(MemoItem item) async {
    final updated = await _requestItem(
      'PATCH',
      '/planning/memos/${item.id}',
      {
        'status': planningStatusApiValue(item.status),
        'archivedAt': item.archivedAt?.toIso8601String(),
      },
    );
    return MemoItem.fromJson(updated);
  }

  Future<Map<String, dynamic>> _requestJson(String path) async {
    final request = await _httpClient.getUrl(_baseUri.resolve(path));
    await _applyAuthorization(request);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlanningRepositoryException(
        'Request failed with ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const PlanningRepositoryException('Unexpected response payload');
  }

  Future<Map<String, dynamic>> _requestItem(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final request = await _httpClient.openUrl(method, _baseUri.resolve(path));
    request.headers.contentType = ContentType.json;
    await _applyAuthorization(request);
    request.write(jsonEncode(payload));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlanningRepositoryException(
        body.isEmpty ? 'Request failed with ${response.statusCode}' : body,
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw const PlanningRepositoryException('Unexpected response payload');
  }

  Future<void> _requestEmpty(String method, String path) async {
    final request = await _httpClient.openUrl(method, _baseUri.resolve(path));
    await _applyAuthorization(request);
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw PlanningRepositoryException(
        body.isEmpty ? 'Request failed with ${response.statusCode}' : body,
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> _applyAuthorization(HttpClientRequest request) async {
    final session = await _authSessionProvider?.call();
    final token = session?.token;
    if (token == null || token.isEmpty) {
      return;
    }

    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
}

class FakePlanningRepository implements PlanningRepository, PlanningSyncRemote {
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
  Future<void> createSchedule({
    required String title,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    int? durationMinutes,
  }) async {
    final resolvedStartAt =
        startAt ??
        DateTime.utc(2026, 3, 12, 9).add(Duration(hours: _schedules.length));
    await pushSchedule(
      ScheduleItem(
        id: 'local-${_schedules.length + 1}',
        title: title,
        startAt: resolvedStartAt,
        endAt: endAt ?? resolvedStartAt.add(const Duration(hours: 1)),
        location: location,
        durationMinutes: durationMinutes,
      ),
    );
  }

  @override
  Future<void> createTask({
    required String title,
    DateTime? plannedStartAt,
    DateTime? dueAt,
    String? location,
    int? plannedDurationMinutes,
  }) async {
    final resolvedStartAt =
        plannedStartAt ??
        DateTime.utc(2026, 3, 12, 13).add(Duration(hours: _tasks.length));
    await pushTask(
      TaskItem(
        id: 'local-${_tasks.length + 1}',
        title: title,
        plannedStartAt: resolvedStartAt,
        dueAt: dueAt ?? resolvedStartAt.add(const Duration(days: 1)),
        location: location,
        plannedDurationMinutes: plannedDurationMinutes,
      ),
    );
  }

  @override
  Future<void> createMemo({
    required String title,
    String? listId,
    int? estimatedDurationMinutes,
  }) async {
    await pushMemo(
      MemoItem(
        id: 'local-${_memos.length + 1}',
        title: title,
        listId: listId ?? 'inbox',
        estimatedDurationMinutes: estimatedDurationMinutes,
        sortOrder: _memos.length,
      ),
    );
  }

  @override
  Future<void> updateScheduleTitle({
    required String scheduleId,
    required String title,
  }) async {
    final current = _schedules.firstWhere(
      (item) => item.id == scheduleId,
      orElse: () =>
          throw const PlanningRepositoryException('Schedule not found'),
    );
    await updateSchedule(
      ScheduleItem(
        id: current.id,
        title: title,
        startAt: current.startAt,
        endAt: current.endAt,
        description: current.description,
        location: current.location,
        timezone: current.timezone,
        durationMinutes: current.durationMinutes,
        status: current.status,
        syncState: current.syncState,
      ),
    );
  }

  @override
  Future<void> updateTaskTitle({
    required String taskId,
    required String title,
  }) async {
    final current = _tasks.firstWhere(
      (item) => item.id == taskId,
      orElse: () => throw const PlanningRepositoryException('Task not found'),
    );
    await updateTask(
      TaskItem(
        id: current.id,
        title: title,
        plannedStartAt: current.plannedStartAt,
        dueAt: current.dueAt,
        plannedEndAt: current.plannedEndAt,
        description: current.description,
        location: current.location,
        timezone: current.timezone,
        plannedDurationMinutes: current.plannedDurationMinutes,
        status: current.status,
        completionAt: current.completionAt,
        syncState: current.syncState,
      ),
    );
  }

  @override
  Future<void> updateMemoTitle({
    required String memoId,
    required String title,
  }) async {
    final current = _memos.firstWhere(
      (item) => item.id == memoId,
      orElse: () => throw const PlanningRepositoryException('Memo not found'),
    );
    await updateMemo(
      MemoItem(
        id: current.id,
        title: title,
        listId: current.listId,
        description: current.description,
        timezone: current.timezone,
        estimatedDurationMinutes: current.estimatedDurationMinutes,
        sortOrder: current.sortOrder,
        status: current.status,
        archivedAt: current.archivedAt,
        syncState: current.syncState,
      ),
    );
  }

  @override
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    final memo = _memos.firstWhere(
      (item) => item.id == memoId,
      orElse: () => throw const PlanningRepositoryException('Memo not found'),
    );
    await pushMemoArchive(
      MemoItem(
        id: memo.id,
        title: memo.title,
        listId: memo.listId,
        description: memo.description,
        timezone: memo.timezone,
        estimatedDurationMinutes: memo.estimatedDurationMinutes,
        sortOrder: memo.sortOrder,
        status: archived ? PlanningStatus.archived : PlanningStatus.active,
        archivedAt: archived ? DateTime.now().toUtc() : null,
      ),
    );
  }

  @override
  Future<PlanningSyncStatus> fetchSyncStatus() async {
    return const PlanningSyncStatus(
      phase: PlanningSyncPhase.success,
      isRemoteEnabled: true,
      pendingOperationCount: 0,
      pendingItemCount: 0,
      conflictItemCount: 0,
    );
  }

  @override
  Future<PlanningSyncStatus> runSync() async {
    final now = DateTime.now().toUtc();
    return PlanningSyncStatus(
      phase: PlanningSyncPhase.success,
      isRemoteEnabled: true,
      pendingOperationCount: 0,
      pendingItemCount: 0,
      conflictItemCount: 0,
      lastAttemptAt: now,
      lastSuccessAt: now,
    );
  }

  @override
  Future<ScheduleItem> pushSchedule(ScheduleItem item) async {
    final synced = ScheduleItem(
      id: item.id.startsWith('local-') ? 'schedule-${_schedules.length + 1}' : item.id,
      title: item.title,
      startAt: item.startAt,
      endAt: item.endAt,
      description: item.description,
      location: item.location,
      timezone: item.timezone,
      durationMinutes: item.durationMinutes,
      status: item.status,
      syncState: SyncState.synced,
    );

    _schedules.removeWhere((existing) => existing.id == item.id);
    _schedules.add(synced);
    return synced;
  }

  @override
  Future<ScheduleItem> updateSchedule(ScheduleItem item) async {
    final index = _schedules.indexWhere((schedule) => schedule.id == item.id);
    if (index == -1) {
      throw const PlanningRepositoryException('Schedule not found');
    }

    final updated = ScheduleItem(
      id: item.id,
      title: item.title,
      startAt: item.startAt,
      endAt: item.endAt,
      description: item.description,
      location: item.location,
      timezone: item.timezone,
      durationMinutes: item.durationMinutes,
      status: item.status,
      syncState: SyncState.synced,
    );
    _schedules[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteSchedule({required String scheduleId}) async {
    final beforeLength = _schedules.length;
    _schedules.removeWhere((item) => item.id == scheduleId);
    if (_schedules.length == beforeLength) {
      throw const PlanningRepositoryException('Schedule not found');
    }
  }

  @override
  Future<TaskItem> pushTask(TaskItem item) async {
    final synced = TaskItem(
      id: item.id.startsWith('local-') ? 'task-${_tasks.length + 1}' : item.id,
      title: item.title,
      plannedStartAt: item.plannedStartAt,
      dueAt: item.dueAt,
      plannedEndAt: item.plannedEndAt,
      description: item.description,
      location: item.location,
      timezone: item.timezone,
      plannedDurationMinutes: item.plannedDurationMinutes,
      status: item.status,
      completionAt: item.completionAt,
      syncState: SyncState.synced,
    );

    _tasks.removeWhere((existing) => existing.id == item.id);
    _tasks.add(synced);
    return synced;
  }

  @override
  Future<TaskItem> updateTask(TaskItem item) async {
    final index = _tasks.indexWhere((task) => task.id == item.id);
    if (index == -1) {
      throw const PlanningRepositoryException('Task not found');
    }

    final updated = TaskItem(
      id: item.id,
      title: item.title,
      plannedStartAt: item.plannedStartAt,
      dueAt: item.dueAt,
      plannedEndAt: item.plannedEndAt,
      description: item.description,
      location: item.location,
      timezone: item.timezone,
      plannedDurationMinutes: item.plannedDurationMinutes,
      status: item.status,
      completionAt: item.completionAt,
      syncState: SyncState.synced,
    );
    _tasks[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    final beforeLength = _tasks.length;
    _tasks.removeWhere((item) => item.id == taskId);
    if (_tasks.length == beforeLength) {
      throw const PlanningRepositoryException('Task not found');
    }
  }

  @override
  Future<MemoItem> pushMemo(MemoItem item) async {
    final synced = MemoItem(
      id: item.id.startsWith('local-') ? 'memo-${_memos.length + 1}' : item.id,
      title: item.title,
      listId: item.listId,
      description: item.description,
      timezone: item.timezone,
      estimatedDurationMinutes: item.estimatedDurationMinutes,
      sortOrder: item.sortOrder,
      status: item.status,
      archivedAt: item.archivedAt,
      syncState: SyncState.synced,
    );

    _memos.removeWhere((existing) => existing.id == item.id);
    _memos.add(synced);
    return synced;
  }

  @override
  Future<MemoItem> updateMemo(MemoItem item) async {
    final index = _memos.indexWhere((memo) => memo.id == item.id);
    if (index == -1) {
      throw const PlanningRepositoryException('Memo not found');
    }

    final updated = MemoItem(
      id: item.id,
      title: item.title,
      listId: item.listId,
      description: item.description,
      timezone: item.timezone,
      estimatedDurationMinutes: item.estimatedDurationMinutes,
      sortOrder: item.sortOrder,
      status: item.status,
      archivedAt: item.archivedAt,
      syncState: SyncState.synced,
    );
    _memos[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteMemo({required String memoId}) async {
    final beforeLength = _memos.length;
    _memos.removeWhere((item) => item.id == memoId);
    if (_memos.length == beforeLength) {
      throw const PlanningRepositoryException('Memo not found');
    }
  }

  @override
  Future<MemoItem> pushMemoArchive(MemoItem item) async {
    final index = _memos.indexWhere((memo) => memo.id == item.id);
    if (index == -1) {
      throw const PlanningRepositoryException('Memo not found');
    }

    final current = _memos[index];
    final updated = MemoItem(
      id: current.id,
      title: current.title,
      listId: current.listId,
      description: current.description,
      timezone: current.timezone,
      estimatedDurationMinutes: current.estimatedDurationMinutes,
      sortOrder: current.sortOrder,
      status: item.status,
      archivedAt: item.archivedAt,
      syncState: SyncState.synced,
    );
    _memos[index] = updated;
    return updated;
  }
}

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class LocalPlanningRepository implements PlanningRepository {
  LocalPlanningRepository({
    SharedPreferencesLoader? preferencesLoader,
    PlanningSyncRemote? remoteRepository,
  })  : _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _remoteRepository = remoteRepository;

  static const _storageKey = 'overview.planning.state.v1';

  final SharedPreferencesLoader _preferencesLoader;
  final PlanningSyncRemote? _remoteRepository;
  Future<_PlanningLocalState>? _stateFuture;

  bool get _isRemoteEnabled => _remoteRepository != null;

  @override
  Future<List<ScheduleItem>> fetchSchedules() async {
    final state = await _loadState();
    return List.of(state.schedules);
  }

  @override
  Future<List<TaskItem>> fetchTasks() async {
    final state = await _loadState();
    return List.of(state.tasks);
  }

  @override
  Future<List<MemoItem>> fetchMemos() async {
    final state = await _loadState();
    return List.of(state.memos);
  }

  @override
  Future<void> createSchedule({
    required String title,
    DateTime? startAt,
    DateTime? endAt,
    String? location,
    int? durationMinutes,
  }) async {
    final now = DateTime.now().toUtc();
    await _updateState((current) {
      final nextIndex = current.schedules.length + 1;
      final resolvedStartAt =
          startAt ?? now.add(Duration(hours: current.schedules.length));
      final item = ScheduleItem(
        id: 'local-schedule-${now.microsecondsSinceEpoch}-$nextIndex',
        title: title,
        startAt: resolvedStartAt,
        endAt: endAt ?? resolvedStartAt.add(const Duration(hours: 1)),
        location: location,
        durationMinutes: durationMinutes,
        syncState: SyncState.pendingPush,
      );
      return _withPendingOperation(
        current.copyWith(
          schedules: [...current.schedules, item],
        ),
        _PendingSyncOperation.create(
          type: _PendingSyncOperationType.createSchedule,
          itemId: item.id,
        ),
      );
    });
  }

  @override
  Future<void> createTask({
    required String title,
    DateTime? plannedStartAt,
    DateTime? dueAt,
    String? location,
    int? plannedDurationMinutes,
  }) async {
    final now = DateTime.now().toUtc();
    await _updateState((current) {
      final nextIndex = current.tasks.length + 1;
      final resolvedStartAt = plannedStartAt ?? now;
      final item = TaskItem(
        id: 'local-task-${now.microsecondsSinceEpoch}-$nextIndex',
        title: title,
        plannedStartAt: resolvedStartAt,
        dueAt: dueAt ?? resolvedStartAt.add(const Duration(days: 1)),
        location: location,
        plannedDurationMinutes: plannedDurationMinutes,
        syncState: SyncState.pendingPush,
      );
      return _withPendingOperation(
        current.copyWith(
          tasks: [...current.tasks, item],
        ),
        _PendingSyncOperation.create(
          type: _PendingSyncOperationType.createTask,
          itemId: item.id,
        ),
      );
    });
  }

  @override
  Future<void> createMemo({
    required String title,
    String? listId,
    int? estimatedDurationMinutes,
  }) async {
    final now = DateTime.now().toUtc();
    await _updateState((current) {
      final nextIndex = current.memos.length + 1;
      final item = MemoItem(
        id: 'local-memo-${now.microsecondsSinceEpoch}-$nextIndex',
        title: title,
        listId: listId ?? 'inbox',
        estimatedDurationMinutes: estimatedDurationMinutes,
        sortOrder: current.memos.length,
        syncState: SyncState.pendingPush,
      );
      return _withPendingOperation(
        current.copyWith(
          memos: [...current.memos, item],
        ),
        _PendingSyncOperation.create(
          type: _PendingSyncOperationType.createMemo,
          itemId: item.id,
        ),
      );
    });
  }

  @override
  Future<void> updateScheduleTitle({
    required String scheduleId,
    required String title,
  }) async {
    await _updateState((current) {
      final schedule = current.schedules.firstWhere(
        (item) => item.id == scheduleId,
        orElse: () =>
            throw const PlanningRepositoryException('Schedule not found'),
      );
      final updated = ScheduleItem(
        id: schedule.id,
        title: title,
        startAt: schedule.startAt,
        endAt: schedule.endAt,
        description: schedule.description,
        location: schedule.location,
        timezone: schedule.timezone,
        durationMinutes: schedule.durationMinutes,
        status: schedule.status,
        syncState: schedule.syncState == SyncState.synced
            ? SyncState.pendingPush
            : schedule.syncState,
      );
      return _queueScheduleMutation(
        _replaceSchedule(current, schedule.id, updated),
        scheduleId: schedule.id,
        type: _PendingSyncOperationType.updateSchedule,
      );
    });
  }

  @override
  Future<void> updateTaskTitle({
    required String taskId,
    required String title,
  }) async {
    await _updateState((current) {
      final task = current.tasks.firstWhere(
        (item) => item.id == taskId,
        orElse: () => throw const PlanningRepositoryException('Task not found'),
      );
      final updated = TaskItem(
        id: task.id,
        title: title,
        plannedStartAt: task.plannedStartAt,
        dueAt: task.dueAt,
        plannedEndAt: task.plannedEndAt,
        description: task.description,
        location: task.location,
        timezone: task.timezone,
        plannedDurationMinutes: task.plannedDurationMinutes,
        status: task.status,
        completionAt: task.completionAt,
        syncState: task.syncState == SyncState.synced
            ? SyncState.pendingPush
            : task.syncState,
      );
      return _queueTaskMutation(
        _replaceTask(current, task.id, updated),
        taskId: task.id,
        type: _PendingSyncOperationType.updateTask,
      );
    });
  }

  @override
  Future<void> updateMemoTitle({
    required String memoId,
    required String title,
  }) async {
    await _updateState((current) {
      final memo = current.memos.firstWhere(
        (item) => item.id == memoId,
        orElse: () => throw const PlanningRepositoryException('Memo not found'),
      );
      final updated = MemoItem(
        id: memo.id,
        title: title,
        listId: memo.listId,
        description: memo.description,
        timezone: memo.timezone,
        estimatedDurationMinutes: memo.estimatedDurationMinutes,
        sortOrder: memo.sortOrder,
        status: memo.status,
        archivedAt: memo.archivedAt,
        syncState: memo.syncState == SyncState.synced
            ? SyncState.pendingPush
            : memo.syncState,
      );
      return _queueMemoMutation(
        _replaceMemo(current, memo.id, updated),
        memoId: memo.id,
        type: _PendingSyncOperationType.updateMemo,
      );
    });
  }

  @override
  Future<void> deleteSchedule({required String scheduleId}) async {
    await _updateState((current) {
      final schedule = current.schedules.firstWhere(
        (item) => item.id == scheduleId,
        orElse: () =>
            throw const PlanningRepositoryException('Schedule not found'),
      );
      if (_hasPendingOperation(
        current,
        itemId: scheduleId,
        type: _PendingSyncOperationType.createSchedule,
      )) {
        return _removeScheduleAndOperations(current, scheduleId);
      }

      final updated = ScheduleItem(
        id: schedule.id,
        title: schedule.title,
        startAt: schedule.startAt,
        endAt: schedule.endAt,
        description: schedule.description,
        location: schedule.location,
        timezone: schedule.timezone,
        durationMinutes: schedule.durationMinutes,
        status: schedule.status,
        syncState: SyncState.pendingDelete,
      );
      return _queueScheduleMutation(
        _replaceSchedule(current, schedule.id, updated),
        scheduleId: schedule.id,
        type: _PendingSyncOperationType.deleteSchedule,
      );
    });
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    await _updateState((current) {
      final task = current.tasks.firstWhere(
        (item) => item.id == taskId,
        orElse: () => throw const PlanningRepositoryException('Task not found'),
      );
      if (_hasPendingOperation(
        current,
        itemId: taskId,
        type: _PendingSyncOperationType.createTask,
      )) {
        return _removeTaskAndOperations(current, taskId);
      }

      final updated = TaskItem(
        id: task.id,
        title: task.title,
        plannedStartAt: task.plannedStartAt,
        dueAt: task.dueAt,
        plannedEndAt: task.plannedEndAt,
        description: task.description,
        location: task.location,
        timezone: task.timezone,
        plannedDurationMinutes: task.plannedDurationMinutes,
        status: task.status,
        completionAt: task.completionAt,
        syncState: SyncState.pendingDelete,
      );
      return _queueTaskMutation(
        _replaceTask(current, task.id, updated),
        taskId: task.id,
        type: _PendingSyncOperationType.deleteTask,
      );
    });
  }

  @override
  Future<void> deleteMemo({required String memoId}) async {
    await _updateState((current) {
      final memo = current.memos.firstWhere(
        (item) => item.id == memoId,
        orElse: () => throw const PlanningRepositoryException('Memo not found'),
      );
      if (_hasPendingOperation(
        current,
        itemId: memoId,
        type: _PendingSyncOperationType.createMemo,
      )) {
        return _removeMemoAndOperations(current, memoId);
      }

      final updated = MemoItem(
        id: memo.id,
        title: memo.title,
        listId: memo.listId,
        description: memo.description,
        timezone: memo.timezone,
        estimatedDurationMinutes: memo.estimatedDurationMinutes,
        sortOrder: memo.sortOrder,
        status: memo.status,
        archivedAt: memo.archivedAt,
        syncState: SyncState.pendingDelete,
      );
      return _queueMemoMutation(
        _replaceMemo(current, memo.id, updated),
        memoId: memo.id,
        type: _PendingSyncOperationType.deleteMemo,
      );
    });
  }

  @override
  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    final archivedAt = archived ? DateTime.now().toUtc() : null;
    await _updateState((current) {
      final index = current.memos.indexWhere((memo) => memo.id == memoId);
      if (index == -1) {
        throw const PlanningRepositoryException('Memo not found');
      }

      final currentMemo = current.memos[index];
      final nextMemos = List<MemoItem>.of(current.memos);
      nextMemos[index] = MemoItem(
        id: currentMemo.id,
        title: currentMemo.title,
        listId: currentMemo.listId,
        description: currentMemo.description,
        timezone: currentMemo.timezone,
        estimatedDurationMinutes: currentMemo.estimatedDurationMinutes,
        sortOrder: currentMemo.sortOrder,
        status: archived ? PlanningStatus.archived : PlanningStatus.active,
        archivedAt: archivedAt,
        syncState: SyncState.pendingPush,
      );

      return _queueMemoMutation(
        current.copyWith(memos: nextMemos),
        memoId: memoId,
        type: _PendingSyncOperationType.updateMemoArchive,
      );
    });
  }

  @override
  Future<PlanningSyncStatus> fetchSyncStatus() async {
    final state = await _loadState();
    return state.syncStatus;
  }

  @override
  Future<PlanningSyncStatus> runSync() async {
    final attemptAt = DateTime.now().toUtc();
    final current = await _loadState();
    final syncingState = _recalculateState(
      current.copyWith(
        syncStatus: current.syncStatus.copyWith(
          phase: PlanningSyncPhase.syncing,
          isRemoteEnabled: _isRemoteEnabled,
          lastAttemptAt: attemptAt,
          clearLastError: true,
        ),
      ),
    );
    await _persistState(syncingState);

    if (_remoteRepository == null) {
      final blockedState = _recalculateState(
        syncingState.copyWith(
          syncStatus: syncingState.syncStatus.copyWith(
            phase: PlanningSyncPhase.blocked,
            lastAttemptAt: attemptAt,
            lastError: 'Remote sync is not configured.',
          ),
        ),
      );
      await _persistState(blockedState);
      return blockedState.syncStatus;
    }

    final remoteRepository = _remoteRepository;

    var working = syncingState;
    try {
      while (working.pendingOperations.isNotEmpty) {
        final operation = working.pendingOperations.first;
        try {
          working = await _applyPendingOperation(working, operation);
          working = _removePendingOperation(working, operation.id);
          await _persistState(working);
        } catch (error) {
          if (_isConflictError(error)) {
            final conflictedState = _recalculateState(
              _markOperationConflict(working, operation).copyWith(
                syncStatus: working.syncStatus.copyWith(
                  phase: PlanningSyncPhase.blocked,
                  lastAttemptAt: attemptAt,
                  lastError: _formatConflictError(operation),
                ),
              ),
            );
            await _persistState(conflictedState);
            return conflictedState.syncStatus;
          }

          rethrow;
        }
      }

      final refreshed = _recalculateState(
        working.copyWith(
          schedules: (await remoteRepository.fetchSchedules())
              .map(_markScheduleSynced)
              .toList(),
          tasks: (await remoteRepository.fetchTasks())
              .map(_markTaskSynced)
              .toList(),
          memos: (await remoteRepository.fetchMemos())
              .map(_markMemoSynced)
              .toList(),
          syncStatus: working.syncStatus.copyWith(
            phase: PlanningSyncPhase.success,
            lastAttemptAt: attemptAt,
            lastSuccessAt: DateTime.now().toUtc(),
            clearLastError: true,
          ),
        ),
      );
      await _persistState(refreshed);
      return refreshed.syncStatus;
    } catch (error) {
      final isAuthBlocked = _isAuthBlockedError(error);
      final failedState = _recalculateState(
        working.copyWith(
          syncStatus: working.syncStatus.copyWith(
            phase: isAuthBlocked
                ? PlanningSyncPhase.blocked
                : PlanningSyncPhase.failed,
            lastAttemptAt: attemptAt,
            lastError: isAuthBlocked
                ? 'Authentication required before sync can continue.'
                : error.toString(),
          ),
        ),
      );
      await _persistState(failedState);
      return failedState.syncStatus;
    }
  }

  Future<_PlanningLocalState> _applyPendingOperation(
    _PlanningLocalState state,
    _PendingSyncOperation operation,
  ) async {
    switch (operation.type) {
      case _PendingSyncOperationType.createSchedule:
        final local = state.schedules.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () => throw const PlanningRepositoryException(
            'Pending schedule not found',
          ),
        );
        final remote = await _remoteRepository!.pushSchedule(local);
        return _replaceSchedule(state, local.id, _markScheduleSynced(remote));
      case _PendingSyncOperationType.createTask:
        final local = state.tasks.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () =>
              throw const PlanningRepositoryException('Pending task not found'),
        );
        final remote = await _remoteRepository!.pushTask(local);
        return _replaceTask(state, local.id, _markTaskSynced(remote));
      case _PendingSyncOperationType.createMemo:
        final local = state.memos.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () =>
              throw const PlanningRepositoryException('Pending memo not found'),
        );
        final remote = await _remoteRepository!.pushMemo(local);
        return _replaceMemo(state, local.id, _markMemoSynced(remote));
      case _PendingSyncOperationType.updateSchedule:
        final local = state.schedules.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () => throw const PlanningRepositoryException(
            'Pending schedule not found',
          ),
        );
        final remote = await _remoteRepository!.updateSchedule(local);
        return _replaceSchedule(state, local.id, _markScheduleSynced(remote));
      case _PendingSyncOperationType.updateTask:
        final local = state.tasks.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () =>
              throw const PlanningRepositoryException('Pending task not found'),
        );
        final remote = await _remoteRepository!.updateTask(local);
        return _replaceTask(state, local.id, _markTaskSynced(remote));
      case _PendingSyncOperationType.updateMemo:
        final local = state.memos.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () =>
              throw const PlanningRepositoryException('Pending memo not found'),
        );
        final remote = await _remoteRepository!.updateMemo(local);
        return _replaceMemo(state, local.id, _markMemoSynced(remote));
      case _PendingSyncOperationType.updateMemoArchive:
        final local = state.memos.firstWhere(
          (item) => item.id == operation.itemId,
          orElse: () =>
              throw const PlanningRepositoryException('Pending memo not found'),
        );
        final remote = await _remoteRepository!.pushMemoArchive(local);
        return _replaceMemo(state, local.id, _markMemoSynced(remote));
      case _PendingSyncOperationType.deleteSchedule:
        await _remoteRepository!.deleteSchedule(scheduleId: operation.itemId);
        return _removeScheduleAndOperations(state, operation.itemId);
      case _PendingSyncOperationType.deleteTask:
        await _remoteRepository!.deleteTask(taskId: operation.itemId);
        return _removeTaskAndOperations(state, operation.itemId);
      case _PendingSyncOperationType.deleteMemo:
        await _remoteRepository!.deleteMemo(memoId: operation.itemId);
        return _removeMemoAndOperations(state, operation.itemId);
    }
  }

  Future<_PlanningLocalState> _loadState() {
    return _stateFuture ??= _readState();
  }

  Future<_PlanningLocalState> _readState() async {
    final preferences = await _preferencesLoader();
    final rawValue = preferences.getString(_storageKey);

    if (rawValue == null || rawValue.isEmpty) {
      final seededState = _PlanningLocalState.seeded(
        isRemoteEnabled: _isRemoteEnabled,
      );
      await _saveState(preferences, seededState);
      return seededState;
    }

    try {
      final decoded = jsonDecode(rawValue);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Unexpected local planning payload');
      }
      return _recalculateState(
        _PlanningLocalState.fromJson(
          decoded,
          isRemoteEnabled: _isRemoteEnabled,
        ),
      );
    } catch (_) {
      final seededState = _PlanningLocalState.seeded(
        isRemoteEnabled: _isRemoteEnabled,
      );
      await _saveState(preferences, seededState);
      return seededState;
    }
  }

  Future<void> _updateState(
    _PlanningLocalState Function(_PlanningLocalState current) transform,
  ) async {
    final current = await _loadState();
    final next = _recalculateState(transform(current));
    await _persistState(next);
  }

  Future<void> _persistState(_PlanningLocalState state) async {
    final preferences = await _preferencesLoader();
    await _saveState(preferences, state);
    _stateFuture = Future.value(state);
  }

  Future<void> _saveState(
    SharedPreferences preferences,
    _PlanningLocalState state,
  ) async {
    await preferences.setString(_storageKey, jsonEncode(state.toJson()));
  }

  _PlanningLocalState _recalculateState(_PlanningLocalState state) {
    final pendingItemCount = state.schedules
            .where((item) => item.syncState != SyncState.synced)
            .length +
        state.tasks.where((item) => item.syncState != SyncState.synced).length +
        state.memos.where((item) => item.syncState != SyncState.synced).length;
    final conflictItemCount = state.schedules
            .where((item) => item.syncState == SyncState.conflict)
            .length +
        state.tasks
            .where((item) => item.syncState == SyncState.conflict)
            .length +
        state.memos.where((item) => item.syncState == SyncState.conflict).length;
    return state.copyWith(
      syncStatus: state.syncStatus.copyWith(
        isRemoteEnabled: _isRemoteEnabled,
        pendingOperationCount: state.pendingOperations.length,
        pendingItemCount: pendingItemCount,
        conflictItemCount: conflictItemCount,
      ),
    );
  }

  bool _isAuthBlockedError(Object error) {
    return error is PlanningRepositoryException && error.statusCode == 401;
  }

  bool _isConflictError(Object error) {
    return error is PlanningRepositoryException &&
        (error.statusCode == 404 || error.statusCode == 409);
  }

  String _formatConflictError(_PendingSyncOperation operation) {
    return 'Sync conflict detected for ${operation.itemId}. Resolve it before retrying.';
  }
}

class PlanningRepositoryException implements Exception {
  const PlanningRepositoryException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class _PlanningLocalState {
  const _PlanningLocalState({
    required this.schedules,
    required this.tasks,
    required this.memos,
    required this.pendingOperations,
    required this.syncStatus,
  });

  factory _PlanningLocalState.fromJson(
    Map<String, dynamic> json, {
    required bool isRemoteEnabled,
  }) {
    final schedules = json['schedules'] as List<dynamic>? ?? const [];
    final tasks = json['tasks'] as List<dynamic>? ?? const [];
    final memos = json['memos'] as List<dynamic>? ?? const [];
    final pendingOperations =
        json['pendingOperations'] as List<dynamic>? ?? const [];

    return _PlanningLocalState(
      schedules: schedules
          .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      tasks: tasks
          .map((item) => TaskItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      memos: memos
          .map((item) => MemoItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      pendingOperations: pendingOperations
          .map(
            (item) => _PendingSyncOperation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      syncStatus: json['syncStatus'] is Map<String, dynamic>
          ? PlanningSyncStatus.fromJson(
              json['syncStatus'] as Map<String, dynamic>,
            ).copyWith(isRemoteEnabled: isRemoteEnabled)
          : PlanningSyncStatus.initial(isRemoteEnabled: isRemoteEnabled),
    );
  }

  factory _PlanningLocalState.seeded({required bool isRemoteEnabled}) {
    return _PlanningLocalState(
      schedules: List.of(_seedSchedules),
      tasks: List.of(_seedTasks),
      memos: List.of(_seedMemos),
      pendingOperations: const [],
      syncStatus: PlanningSyncStatus.initial(isRemoteEnabled: isRemoteEnabled),
    );
  }

  final List<ScheduleItem> schedules;
  final List<TaskItem> tasks;
  final List<MemoItem> memos;
  final List<_PendingSyncOperation> pendingOperations;
  final PlanningSyncStatus syncStatus;

  _PlanningLocalState copyWith({
    List<ScheduleItem>? schedules,
    List<TaskItem>? tasks,
    List<MemoItem>? memos,
    List<_PendingSyncOperation>? pendingOperations,
    PlanningSyncStatus? syncStatus,
  }) {
    return _PlanningLocalState(
      schedules: schedules ?? this.schedules,
      tasks: tasks ?? this.tasks,
      memos: memos ?? this.memos,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedules': schedules.map((item) => item.toJson()).toList(),
      'tasks': tasks.map((item) => item.toJson()).toList(),
      'memos': memos.map((item) => item.toJson()).toList(),
      'pendingOperations': pendingOperations.map((item) => item.toJson()).toList(),
      'syncStatus': syncStatus.toJson(),
    };
  }
}

enum _PendingSyncOperationType {
  createSchedule,
  createTask,
  createMemo,
  updateSchedule,
  updateTask,
  updateMemo,
  updateMemoArchive,
  deleteSchedule,
  deleteTask,
  deleteMemo,
}

class _PendingSyncOperation {
  const _PendingSyncOperation({
    required this.id,
    required this.type,
    required this.itemId,
    required this.createdAt,
  });

  factory _PendingSyncOperation.create({
    required _PendingSyncOperationType type,
    required String itemId,
  }) {
    final now = DateTime.now().toUtc();
    return _PendingSyncOperation(
      id: '${type.name}-${now.microsecondsSinceEpoch}',
      type: type,
      itemId: itemId,
      createdAt: now,
    );
  }

  factory _PendingSyncOperation.fromJson(Map<String, dynamic> json) {
    return _PendingSyncOperation(
      id: json['id'] as String,
      type: _parsePendingSyncOperationType(json['type'] as String),
      itemId: json['itemId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  final String id;
  final _PendingSyncOperationType type;
  final String itemId;
  final DateTime createdAt;

  _PendingSyncOperation copyWith({
    String? itemId,
  }) {
    return _PendingSyncOperation(
      id: id,
      type: type,
      itemId: itemId ?? this.itemId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'itemId': itemId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

_PendingSyncOperationType _parsePendingSyncOperationType(String value) {
  switch (value) {
    case 'createTask':
      return _PendingSyncOperationType.createTask;
    case 'createMemo':
      return _PendingSyncOperationType.createMemo;
    case 'updateSchedule':
      return _PendingSyncOperationType.updateSchedule;
    case 'updateTask':
      return _PendingSyncOperationType.updateTask;
    case 'updateMemo':
      return _PendingSyncOperationType.updateMemo;
    case 'updateMemoArchive':
      return _PendingSyncOperationType.updateMemoArchive;
    case 'deleteSchedule':
      return _PendingSyncOperationType.deleteSchedule;
    case 'deleteTask':
      return _PendingSyncOperationType.deleteTask;
    case 'deleteMemo':
      return _PendingSyncOperationType.deleteMemo;
    case 'createSchedule':
    default:
      return _PendingSyncOperationType.createSchedule;
  }
}

_PlanningLocalState _withPendingOperation(
  _PlanningLocalState state,
  _PendingSyncOperation operation,
) {
  return state.copyWith(
    pendingOperations: [...state.pendingOperations, operation],
    syncStatus: state.syncStatus.copyWith(
      phase: PlanningSyncPhase.idle,
      clearLastError: true,
    ),
  );
}

_PlanningLocalState _queueScheduleMutation(
  _PlanningLocalState state, {
  required String scheduleId,
  required _PendingSyncOperationType type,
}) {
  if (_hasPendingOperation(
    state,
    itemId: scheduleId,
    type: _PendingSyncOperationType.createSchedule,
  )) {
    return state;
  }

  return _enqueueOperation(
    state,
    _PendingSyncOperation.create(type: type, itemId: scheduleId),
    replacedTypes: {
      _PendingSyncOperationType.updateSchedule,
      _PendingSyncOperationType.deleteSchedule,
    },
  );
}

_PlanningLocalState _queueTaskMutation(
  _PlanningLocalState state, {
  required String taskId,
  required _PendingSyncOperationType type,
}) {
  if (_hasPendingOperation(
    state,
    itemId: taskId,
    type: _PendingSyncOperationType.createTask,
  )) {
    return state;
  }

  return _enqueueOperation(
    state,
    _PendingSyncOperation.create(type: type, itemId: taskId),
    replacedTypes: {
      _PendingSyncOperationType.updateTask,
      _PendingSyncOperationType.deleteTask,
    },
  );
}

_PlanningLocalState _queueMemoMutation(
  _PlanningLocalState state, {
  required String memoId,
  required _PendingSyncOperationType type,
}) {
  final hasPendingCreate = _hasPendingOperation(
    state,
    itemId: memoId,
    type: _PendingSyncOperationType.createMemo,
  );
  if (hasPendingCreate && type != _PendingSyncOperationType.updateMemoArchive) {
    return state;
  }

  return _enqueueOperation(
    state,
    _PendingSyncOperation.create(type: type, itemId: memoId),
    replacedTypes: {
      _PendingSyncOperationType.updateMemo,
      _PendingSyncOperationType.updateMemoArchive,
      _PendingSyncOperationType.deleteMemo,
    },
  );
}

_PlanningLocalState _enqueueOperation(
  _PlanningLocalState state,
  _PendingSyncOperation operation, {
  required Set<_PendingSyncOperationType> replacedTypes,
}) {
  final nextOperations = state.pendingOperations
      .where(
        (existing) =>
            existing.itemId != operation.itemId ||
            !replacedTypes.contains(existing.type),
      )
      .toList();
  return _withPendingOperation(
    state.copyWith(pendingOperations: nextOperations),
    operation,
  );
}

_PlanningLocalState _removePendingOperation(
  _PlanningLocalState state,
  String operationId,
) {
  return state.copyWith(
    pendingOperations: state.pendingOperations
        .where((operation) => operation.id != operationId)
        .toList(),
  );
}

_PlanningLocalState _markOperationConflict(
  _PlanningLocalState state,
  _PendingSyncOperation operation,
) {
  switch (operation.type) {
    case _PendingSyncOperationType.createSchedule:
    case _PendingSyncOperationType.updateSchedule:
    case _PendingSyncOperationType.deleteSchedule:
      final schedule = state.schedules.firstWhere(
        (item) => item.id == operation.itemId,
        orElse: () => throw const PlanningRepositoryException(
          'Pending schedule not found',
        ),
      );
      return _replaceSchedule(
        _removeOperationsForItem(state, operation.itemId),
        schedule.id,
        ScheduleItem(
          id: schedule.id,
          title: schedule.title,
          startAt: schedule.startAt,
          endAt: schedule.endAt,
          description: schedule.description,
          location: schedule.location,
          timezone: schedule.timezone,
          durationMinutes: schedule.durationMinutes,
          status: schedule.status,
          syncState: SyncState.conflict,
        ),
      );
    case _PendingSyncOperationType.createTask:
    case _PendingSyncOperationType.updateTask:
    case _PendingSyncOperationType.deleteTask:
      final task = state.tasks.firstWhere(
        (item) => item.id == operation.itemId,
        orElse: () => throw const PlanningRepositoryException(
          'Pending task not found',
        ),
      );
      return _replaceTask(
        _removeOperationsForItem(state, operation.itemId),
        task.id,
        TaskItem(
          id: task.id,
          title: task.title,
          plannedStartAt: task.plannedStartAt,
          dueAt: task.dueAt,
          plannedEndAt: task.plannedEndAt,
          description: task.description,
          location: task.location,
          timezone: task.timezone,
          plannedDurationMinutes: task.plannedDurationMinutes,
          status: task.status,
          completionAt: task.completionAt,
          syncState: SyncState.conflict,
        ),
      );
    case _PendingSyncOperationType.createMemo:
    case _PendingSyncOperationType.updateMemo:
    case _PendingSyncOperationType.updateMemoArchive:
    case _PendingSyncOperationType.deleteMemo:
      final memo = state.memos.firstWhere(
        (item) => item.id == operation.itemId,
        orElse: () => throw const PlanningRepositoryException(
          'Pending memo not found',
        ),
      );
      return _replaceMemo(
        _removeOperationsForItem(state, operation.itemId),
        memo.id,
        MemoItem(
          id: memo.id,
          title: memo.title,
          listId: memo.listId,
          description: memo.description,
          timezone: memo.timezone,
          estimatedDurationMinutes: memo.estimatedDurationMinutes,
          sortOrder: memo.sortOrder,
          status: memo.status,
          archivedAt: memo.archivedAt,
          syncState: SyncState.conflict,
        ),
      );
  }
}

_PlanningLocalState _removeOperationsForItem(
  _PlanningLocalState state,
  String itemId,
) {
  return state.copyWith(
    pendingOperations: state.pendingOperations
        .where((operation) => operation.itemId != itemId)
        .toList(),
  );
}

bool _hasPendingOperation(
  _PlanningLocalState state, {
  required String itemId,
  required _PendingSyncOperationType type,
}) {
  return state.pendingOperations.any(
    (operation) => operation.itemId == itemId && operation.type == type,
  );
}

_PlanningLocalState _replaceSchedule(
  _PlanningLocalState state,
  String oldId,
  ScheduleItem next,
) {
  return state.copyWith(
    schedules: state.schedules
        .map((item) => item.id == oldId ? next : item)
        .toList(),
    pendingOperations: state.pendingOperations
        .map((operation) => operation.itemId == oldId
            ? operation.copyWith(itemId: next.id)
            : operation)
        .toList(),
  );
}

_PlanningLocalState _replaceTask(
  _PlanningLocalState state,
  String oldId,
  TaskItem next,
) {
  return state.copyWith(
    tasks: state.tasks.map((item) => item.id == oldId ? next : item).toList(),
    pendingOperations: state.pendingOperations
        .map((operation) => operation.itemId == oldId
            ? operation.copyWith(itemId: next.id)
            : operation)
        .toList(),
  );
}

_PlanningLocalState _replaceMemo(
  _PlanningLocalState state,
  String oldId,
  MemoItem next,
) {
  return state.copyWith(
    memos: state.memos.map((item) => item.id == oldId ? next : item).toList(),
    pendingOperations: state.pendingOperations
        .map((operation) => operation.itemId == oldId
            ? operation.copyWith(itemId: next.id)
            : operation)
        .toList(),
  );
}

_PlanningLocalState _removeScheduleAndOperations(
  _PlanningLocalState state,
  String scheduleId,
) {
  return state.copyWith(
    schedules: state.schedules
        .where((item) => item.id != scheduleId)
        .toList(),
    pendingOperations: state.pendingOperations
        .where((operation) => operation.itemId != scheduleId)
        .toList(),
  );
}

_PlanningLocalState _removeTaskAndOperations(
  _PlanningLocalState state,
  String taskId,
) {
  return state.copyWith(
    tasks: state.tasks.where((item) => item.id != taskId).toList(),
    pendingOperations: state.pendingOperations
        .where((operation) => operation.itemId != taskId)
        .toList(),
  );
}

_PlanningLocalState _removeMemoAndOperations(
  _PlanningLocalState state,
  String memoId,
) {
  return state.copyWith(
    memos: state.memos.where((item) => item.id != memoId).toList(),
    pendingOperations: state.pendingOperations
        .where((operation) => operation.itemId != memoId)
        .toList(),
  );
}

ScheduleItem _markScheduleSynced(ScheduleItem item) {
  return ScheduleItem(
    id: item.id,
    title: item.title,
    startAt: item.startAt,
    endAt: item.endAt,
    description: item.description,
    location: item.location,
    timezone: item.timezone,
    durationMinutes: item.durationMinutes,
    status: item.status,
    syncState: SyncState.synced,
  );
}

TaskItem _markTaskSynced(TaskItem item) {
  return TaskItem(
    id: item.id,
    title: item.title,
    plannedStartAt: item.plannedStartAt,
    dueAt: item.dueAt,
    plannedEndAt: item.plannedEndAt,
    description: item.description,
    location: item.location,
    timezone: item.timezone,
    plannedDurationMinutes: item.plannedDurationMinutes,
    status: item.status,
    completionAt: item.completionAt,
    syncState: SyncState.synced,
  );
}

MemoItem _markMemoSynced(MemoItem item) {
  return MemoItem(
    id: item.id,
    title: item.title,
    listId: item.listId,
    description: item.description,
    timezone: item.timezone,
    estimatedDurationMinutes: item.estimatedDurationMinutes,
    sortOrder: item.sortOrder,
    status: item.status,
    archivedAt: item.archivedAt,
    syncState: SyncState.synced,
  );
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
