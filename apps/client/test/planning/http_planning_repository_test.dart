import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/planning/planning_models.dart';
import 'package:overview_client/app/planning/planning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late _PlanningApiStubServer server;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    server = await _PlanningApiStubServer.start();
  });

  tearDown(() async {
    await server.close();
  });

  test('pushes and fetches planning items over HTTP', () async {
    final repository = HttpPlanningRepository(
      baseUrl: server.baseUrl,
      authSessionProvider: () async => server.createSession(),
    );

    await repository.createSchedule(title: 'HTTP schedule');
    await repository.createTask(title: 'HTTP task');
    await repository.createMemo(title: 'HTTP memo');

    final schedulesBeforeUpdate = await repository.fetchSchedules();
    final tasksBeforeDelete = await repository.fetchTasks();
    final memos = await repository.fetchMemos();
    await repository.updateScheduleTitle(
      scheduleId: schedulesBeforeUpdate.single.id,
      title: 'HTTP schedule updated',
    );
    await repository.deleteTask(taskId: tasksBeforeDelete.single.id);
    await repository.updateMemoTitle(
      memoId: memos.single.id,
      title: 'HTTP memo updated',
    );
    await repository.setMemoArchived(memoId: memos.single.id, archived: true);

    final schedules = await repository.fetchSchedules();
    final tasks = await repository.fetchTasks();
    final archivedMemos = await repository.fetchMemos();

    expect(schedules.single.title, 'HTTP schedule updated');
    expect(tasks, isEmpty);
    expect(archivedMemos.single.title, 'HTTP memo updated');
    expect(archivedMemos.single.isArchived, isTrue);
    expect(archivedMemos.single.syncState, SyncState.synced);
  });

  test('runs local sync updates and deletes against an HTTP remote', () async {
    final repository = LocalPlanningRepository(
      remoteRepository: HttpPlanningRepository(
        baseUrl: server.baseUrl,
        authSessionProvider: () async => server.createSession(),
      ),
    );

    await repository.createSchedule(title: 'Sync schedule');
    await repository.createTask(title: 'Sync task');
    await repository.createMemo(title: 'Sync memo');

    final syncResult = await repository.runSync();
    final memosAfterCreate = await repository.fetchMemos();
    final syncedMemo = memosAfterCreate.firstWhere(
      (memo) => memo.title == 'Sync memo',
    );

    expect(syncResult.phase, PlanningSyncPhase.success);
    expect(syncResult.pendingOperationCount, 0);
    expect(syncResult.pendingItemCount, 0);
    expect(syncResult.lastSuccessAt, isNotNull);

    final syncedSchedule = (await repository.fetchSchedules()).firstWhere(
      (item) => item.title == 'Sync schedule',
    );
    final syncedTask = (await repository.fetchTasks()).firstWhere(
      (item) => item.title == 'Sync task',
    );
    await repository.setMemoArchived(memoId: syncedMemo.id, archived: true);
    await repository.updateScheduleTitle(
      scheduleId: syncedSchedule.id,
      title: 'Sync schedule updated',
    );
    await repository.deleteTask(taskId: syncedTask.id);
    await repository.updateMemoTitle(
      memoId: syncedMemo.id,
      title: 'Sync memo updated',
    );
    final archiveResult = await repository.runSync();

    final schedules = await repository.fetchSchedules();
    final tasks = await repository.fetchTasks();
    final memos = await repository.fetchMemos();

    expect(archiveResult.phase, PlanningSyncPhase.success);
    expect(
      schedules.any((item) => item.title == 'Sync schedule updated'),
      isTrue,
    );
    expect(tasks.any((item) => item.title == 'Sync task'), isFalse);
    expect(
      memos.firstWhere((item) => item.title == 'Sync memo updated').isArchived,
      isTrue,
    );
    expect(
      server.schedules.any((item) => item.title == 'Sync schedule updated'),
      isTrue,
    );
    expect(server.tasks.any((item) => item.title == 'Sync task'), isFalse);
    expect(
      server.memos
          .firstWhere((item) => item.title == 'Sync memo updated')
          .isArchived,
      isTrue,
    );
  });
}

class _PlanningApiStubServer {
  _PlanningApiStubServer._(this._server);

  static Future<_PlanningApiStubServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final stub = _PlanningApiStubServer._(server);
    stub._listen();
    return stub;
  }

  final HttpServer _server;
  final List<ScheduleItem> schedules = [];
  final List<TaskItem> tasks = [];
  final List<MemoItem> memos = [];
  final String expectedToken = 'token-test';

  String get baseUrl => 'http://${_server.address.host}:${_server.port}';

  AuthSession createSession() {
    return AuthSession(
      token: expectedToken,
      userId: 'user-1',
      email: 'user@example.com',
      expiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
    );
  }

  void _listen() {
    _server.listen((request) async {
      try {
        await _handleRequest(request);
      } catch (_) {
        request.response.statusCode = HttpStatus.internalServerError;
        await _writeJson(request.response, {'error': 'Internal server error'});
      }
    });
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handleRequest(HttpRequest request) async {
    if (request.headers.value(HttpHeaders.authorizationHeader) !=
        'Bearer $expectedToken') {
      request.response.statusCode = HttpStatus.unauthorized;
      await _writeJson(request.response, {'error': 'Authorization required'});
      return;
    }

    final body = await _readBody(request);
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/planning/schedules') {
      await _writeJson(
        request.response,
        {'items': schedules.map((item) => item.toJson()).toList()},
      );
      return;
    }

    if (request.method == 'GET' && path.startsWith('/planning/schedules/')) {
      final scheduleId = path.split('/').last;
      final schedule = _firstWhereOrNull(
        schedules,
        (item) => item.id == scheduleId,
      );
      if (schedule == null) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Schedule not found'});
        return;
      }
      await _writeJson(request.response, schedule.toJson());
      return;
    }

    if (request.method == 'POST' && path == '/planning/schedules') {
      final created = ScheduleItem(
        id: 'schedule-${schedules.length + 1}',
        title: body['title'] as String,
        startAt: DateTime.parse(body['startAt'] as String),
        endAt: body['endAt'] == null
            ? null
            : DateTime.parse(body['endAt'] as String),
        description: body['description'] as String?,
        location: body['location'] as String?,
        timezone: body['timezone'] as String?,
        durationMinutes: body['durationMinutes'] as int?,
        syncState: SyncState.synced,
      );
      schedules
        ..removeWhere((item) => item.id == created.id)
        ..add(created);
      request.response.statusCode = HttpStatus.created;
      await _writeJson(request.response, created.toJson());
      return;
    }

    if (request.method == 'PATCH' && path.startsWith('/planning/schedules/')) {
      final scheduleId = path.split('/').last;
      final index = schedules.indexWhere((item) => item.id == scheduleId);
      if (index == -1) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Schedule not found'});
        return;
      }

      final current = schedules[index];
      final updated = ScheduleItem(
        id: current.id,
        title: body['title'] as String? ?? current.title,
        startAt: body['startAt'] == null
            ? current.startAt
            : DateTime.parse(body['startAt'] as String),
        endAt: body['endAt'] == null
            ? current.endAt
            : DateTime.parse(body['endAt'] as String),
        description: body['description'] as String? ?? current.description,
        location: body['location'] as String? ?? current.location,
        timezone: body['timezone'] as String? ?? current.timezone,
        durationMinutes: body['durationMinutes'] as int? ?? current.durationMinutes,
        status: body['status'] == null
            ? current.status
            : parsePlanningStatus(body['status'] as String?),
        syncState: SyncState.synced,
      );
      schedules[index] = updated;
      await _writeJson(request.response, updated.toJson());
      return;
    }

    if (request.method == 'DELETE' && path.startsWith('/planning/schedules/')) {
      final scheduleId = path.split('/').last;
      schedules.removeWhere((item) => item.id == scheduleId);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/planning/tasks') {
      await _writeJson(
        request.response,
        {'items': tasks.map((item) => item.toJson()).toList()},
      );
      return;
    }

    if (request.method == 'GET' && path.startsWith('/planning/tasks/')) {
      final taskId = path.split('/').last;
      final task = _firstWhereOrNull(tasks, (item) => item.id == taskId);
      if (task == null) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Task not found'});
        return;
      }
      await _writeJson(request.response, task.toJson());
      return;
    }

    if (request.method == 'POST' && path == '/planning/tasks') {
      final created = TaskItem(
        id: 'task-${tasks.length + 1}',
        title: body['title'] as String,
        plannedStartAt: DateTime.parse(body['plannedStartAt'] as String),
        dueAt: DateTime.parse(body['dueAt'] as String),
        plannedEndAt: body['plannedEndAt'] == null
            ? null
            : DateTime.parse(body['plannedEndAt'] as String),
        description: body['description'] as String?,
        location: body['location'] as String?,
        timezone: body['timezone'] as String?,
        plannedDurationMinutes: body['plannedDurationMinutes'] as int?,
        syncState: SyncState.synced,
      );
      tasks
        ..removeWhere((item) => item.id == created.id)
        ..add(created);
      request.response.statusCode = HttpStatus.created;
      await _writeJson(request.response, created.toJson());
      return;
    }

    if (request.method == 'PATCH' && path.startsWith('/planning/tasks/')) {
      final taskId = path.split('/').last;
      final index = tasks.indexWhere((item) => item.id == taskId);
      if (index == -1) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Task not found'});
        return;
      }

      final current = tasks[index];
      final updated = TaskItem(
        id: current.id,
        title: body['title'] as String? ?? current.title,
        plannedStartAt: body['plannedStartAt'] == null
            ? current.plannedStartAt
            : DateTime.parse(body['plannedStartAt'] as String),
        dueAt: body['dueAt'] == null
            ? current.dueAt
            : DateTime.parse(body['dueAt'] as String),
        plannedEndAt: body['plannedEndAt'] == null
            ? current.plannedEndAt
            : DateTime.parse(body['plannedEndAt'] as String),
        description: body['description'] as String? ?? current.description,
        location: body['location'] as String? ?? current.location,
        timezone: body['timezone'] as String? ?? current.timezone,
        plannedDurationMinutes:
            body['plannedDurationMinutes'] as int? ?? current.plannedDurationMinutes,
        status: body['status'] == null
            ? current.status
            : parseTaskStatus(body['status'] as String?),
        completionAt: body['completionAt'] == null
            ? current.completionAt
            : DateTime.parse(body['completionAt'] as String),
        syncState: SyncState.synced,
      );
      tasks[index] = updated;
      await _writeJson(request.response, updated.toJson());
      return;
    }

    if (request.method == 'DELETE' && path.startsWith('/planning/tasks/')) {
      final taskId = path.split('/').last;
      tasks.removeWhere((item) => item.id == taskId);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && path == '/planning/memos') {
      await _writeJson(
        request.response,
        {'items': memos.map((item) => item.toJson()).toList()},
      );
      return;
    }

    if (request.method == 'GET' && path.startsWith('/planning/memos/')) {
      final memoId = path.split('/').last;
      final memo = _firstWhereOrNull(memos, (item) => item.id == memoId);
      if (memo == null) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Memo not found'});
        return;
      }
      await _writeJson(request.response, memo.toJson());
      return;
    }

    if (request.method == 'POST' && path == '/planning/memos') {
      final created = MemoItem(
        id: 'memo-${memos.length + 1}',
        title: body['title'] as String,
        listId: body['listId'] as String,
        description: body['description'] as String?,
        timezone: body['timezone'] as String?,
        estimatedDurationMinutes: body['estimatedDurationMinutes'] as int?,
        sortOrder: body['sortOrder'] as int?,
        syncState: SyncState.synced,
      );
      memos
        ..removeWhere((item) => item.id == created.id)
        ..add(created);
      request.response.statusCode = HttpStatus.created;
      await _writeJson(request.response, created.toJson());
      return;
    }

    if (request.method == 'PATCH' && path.startsWith('/planning/memos/')) {
      final memoId = path.split('/').last;
      final index = memos.indexWhere((item) => item.id == memoId);
      if (index == -1) {
        request.response.statusCode = HttpStatus.notFound;
        await _writeJson(request.response, {'error': 'Memo not found'});
        return;
      }

      final current = memos[index];
      final updated = MemoItem(
        id: current.id,
        title: body['title'] as String? ?? current.title,
        listId: body['listId'] as String? ?? current.listId,
        description: body['description'] as String? ?? current.description,
        timezone: body['timezone'] as String? ?? current.timezone,
        estimatedDurationMinutes: body['estimatedDurationMinutes'] as int? ??
            current.estimatedDurationMinutes,
        sortOrder: body['sortOrder'] as int? ?? current.sortOrder,
        status: body['status'] == null
            ? current.status
            : parsePlanningStatus(body['status'] as String?),
        archivedAt: body['archivedAt'] == null
            ? current.archivedAt
            : DateTime.parse(body['archivedAt'] as String),
        syncState: SyncState.synced,
      );
      memos[index] = updated;
      await _writeJson(request.response, updated.toJson());
      return;
    }

    if (request.method == 'DELETE' && path.startsWith('/planning/memos/')) {
      final memoId = path.split('/').last;
      memos.removeWhere((item) => item.id == memoId);
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await _writeJson(request.response, {'error': 'Not found'});
  }

  Future<Map<String, dynamic>> _readBody(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};
  }

  Future<void> _writeJson(
    HttpResponse response,
    Map<String, dynamic> payload,
  ) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(payload));
    await response.close();
  }
}

T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T item) test) {
  for (final item in items) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}
