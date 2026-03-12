import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/planning/planning_models.dart';
import 'package:overview_client/app/planning/planning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('seeds local planning data on first load', () async {
    final repository = LocalPlanningRepository();

    final schedules = await repository.fetchSchedules();
    final tasks = await repository.fetchTasks();
    final memos = await repository.fetchMemos();

    expect(schedules, isNotEmpty);
    expect(tasks, isNotEmpty);
    expect(memos, isNotEmpty);
  });

  test('persists created memo across repository instances', () async {
    final repository = LocalPlanningRepository();

    await repository.createMemo(title: 'Prepare local storage QA');

    final anotherRepository = LocalPlanningRepository();
    final memos = await anotherRepository.fetchMemos();

    expect(
      memos.any((memo) => memo.title == 'Prepare local storage QA'),
      isTrue,
    );
  });

  test('persists memo archived state across repository instances', () async {
    final repository = LocalPlanningRepository();
    final memo = (await repository.fetchMemos()).first;

    await repository.setMemoArchived(memoId: memo.id, archived: true);

    final anotherRepository = LocalPlanningRepository();
    final archivedMemo = (await anotherRepository.fetchMemos())
        .firstWhere((item) => item.id == memo.id);

    expect(archivedMemo.isArchived, isTrue);
    expect(archivedMemo.archivedAt, isNotNull);
  });

  test('tracks pending sync status after local mutation', () async {
    final repository = LocalPlanningRepository();

    await repository.createMemo(title: 'Sync this later');
    final syncStatus = await repository.fetchSyncStatus();

    expect(syncStatus.pendingOperationCount, 1);
    expect(syncStatus.pendingItemCount, 1);
    expect(syncStatus.phase, PlanningSyncPhase.idle);
  });

  test('runs sync against remote repository and clears pending work', () async {
    final remoteRepository = FakePlanningRepository(
      schedules: const [],
      tasks: const [],
      memos: const [],
    );
    final repository = LocalPlanningRepository(
      remoteRepository: remoteRepository,
    );

    await repository.createMemo(title: 'Push me');

    final beforeSync = await repository.fetchSyncStatus();
    expect(beforeSync.pendingOperationCount, 1);

    final syncResult = await repository.runSync();
    final memos = await repository.fetchMemos();

    expect(syncResult.phase, PlanningSyncPhase.success);
    expect(syncResult.pendingOperationCount, 0);
    expect(syncResult.pendingItemCount, 0);
    expect(syncResult.lastSuccessAt, isNotNull);
    expect(memos.any((memo) => memo.title == 'Push me'), isTrue);
    expect(memos.every((memo) => memo.syncState == SyncState.synced), isTrue);
  });

  test('queues update and delete operations for synced items', () async {
    final remoteRepository = FakePlanningRepository(
      schedules: const [],
      tasks: const [],
      memos: const [],
    );
    final repository = LocalPlanningRepository(
      remoteRepository: remoteRepository,
    );

    await repository.createSchedule(title: 'Schedule before update');
    await repository.createTask(title: 'Task before delete');
    await repository.createMemo(title: 'Memo before update');
    await repository.runSync();

    final schedule = (await repository.fetchSchedules())
        .firstWhere((item) => item.title == 'Schedule before update');
    final task = (await repository.fetchTasks())
        .firstWhere((item) => item.title == 'Task before delete');
    final memo = (await repository.fetchMemos())
        .firstWhere((item) => item.title == 'Memo before update');

    await repository.updateScheduleTitle(
      scheduleId: schedule.id,
      title: 'Schedule after update',
    );
    await repository.updateMemoTitle(
      memoId: memo.id,
      title: 'Memo after update',
    );
    await repository.deleteTask(taskId: task.id);

    final beforeSync = await repository.fetchSyncStatus();
    expect(beforeSync.pendingOperationCount, 3);

    final syncResult = await repository.runSync();
    final schedules = await repository.fetchSchedules();
    final tasks = await repository.fetchTasks();
    final memos = await repository.fetchMemos();

    expect(syncResult.phase, PlanningSyncPhase.success);
    expect(syncResult.pendingOperationCount, 0);
    expect(schedules.any((item) => item.title == 'Schedule after update'), isTrue);
    expect(tasks.any((item) => item.id == task.id), isFalse);
    expect(memos.any((item) => item.title == 'Memo after update'), isTrue);
  });

  test('blocks sync on auth failure and recovers after authorization returns', () async {
    final remoteRepository = _AuthBlockingPlanningRemote();
    final repository = LocalPlanningRepository(
      remoteRepository: remoteRepository,
    );

    await repository.createMemo(title: 'Recover me after login');

    final blockedStatus = await repository.runSync();
    expect(blockedStatus.phase, PlanningSyncPhase.blocked);
    expect(blockedStatus.pendingOperationCount, 1);
    expect(
      blockedStatus.lastError,
      'Authentication required before sync can continue.',
    );

    remoteRepository.isAuthorized = true;

    final recoveredStatus = await repository.runSync();
    final memos = await repository.fetchMemos();

    expect(recoveredStatus.phase, PlanningSyncPhase.success);
    expect(recoveredStatus.pendingOperationCount, 0);
    expect(
      memos.any((memo) => memo.title == 'Recover me after login'),
      isTrue,
    );
    expect(memos.every((memo) => memo.syncState == SyncState.synced), isTrue);
  });
}

class _AuthBlockingPlanningRemote extends FakePlanningRepository {
  _AuthBlockingPlanningRemote()
      : super(
          schedules: const [],
          tasks: const [],
          memos: const [],
        );

  bool isAuthorized = false;

  @override
  Future<List<ScheduleItem>> fetchSchedules() async {
    _requireAuthorization();
    return super.fetchSchedules();
  }

  @override
  Future<List<TaskItem>> fetchTasks() async {
    _requireAuthorization();
    return super.fetchTasks();
  }

  @override
  Future<List<MemoItem>> fetchMemos() async {
    _requireAuthorization();
    return super.fetchMemos();
  }

  @override
  Future<ScheduleItem> pushSchedule(ScheduleItem item) async {
    _requireAuthorization();
    return super.pushSchedule(item);
  }

  @override
  Future<ScheduleItem> updateSchedule(ScheduleItem item) async {
    _requireAuthorization();
    return super.updateSchedule(item);
  }

  @override
  Future<void> deleteSchedule({required String scheduleId}) async {
    _requireAuthorization();
    return super.deleteSchedule(scheduleId: scheduleId);
  }

  @override
  Future<TaskItem> pushTask(TaskItem item) async {
    _requireAuthorization();
    return super.pushTask(item);
  }

  @override
  Future<TaskItem> updateTask(TaskItem item) async {
    _requireAuthorization();
    return super.updateTask(item);
  }

  @override
  Future<void> deleteTask({required String taskId}) async {
    _requireAuthorization();
    return super.deleteTask(taskId: taskId);
  }

  @override
  Future<MemoItem> pushMemo(MemoItem item) async {
    _requireAuthorization();
    return super.pushMemo(item);
  }

  @override
  Future<MemoItem> updateMemo(MemoItem item) async {
    _requireAuthorization();
    return super.updateMemo(item);
  }

  @override
  Future<void> deleteMemo({required String memoId}) async {
    _requireAuthorization();
    return super.deleteMemo(memoId: memoId);
  }

  @override
  Future<MemoItem> pushMemoArchive(MemoItem item) async {
    _requireAuthorization();
    return super.pushMemoArchive(item);
  }

  void _requireAuthorization() {
    if (!isAuthorized) {
      throw const PlanningRepositoryException(
        'Request failed with 401',
        statusCode: 401,
      );
    }
  }
}
