import 'package:flutter/foundation.dart';

import 'planning_models.dart';
import 'planning_repository.dart';

enum CaptureItemKind { schedule, task, memo }

class PlanningStore extends ChangeNotifier {
  PlanningStore({required PlanningRepository repository})
      : _repository = repository;

  final PlanningRepository _repository;

  bool _isLoading = false;
  bool _isSubmitting = false;
  bool _isSyncing = false;
  String? _errorMessage;
  DateTime? _lastUpdatedAt;
  List<ScheduleItem> _schedules = const [];
  List<TaskItem> _tasks = const [];
  List<MemoItem> _memos = const [];
  PlanningSyncStatus _syncStatus = const PlanningSyncStatus(
    phase: PlanningSyncPhase.idle,
    isRemoteEnabled: false,
    pendingOperationCount: 0,
    pendingItemCount: 0,
    conflictItemCount: 0,
  );

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdatedAt => _lastUpdatedAt;
  List<ScheduleItem> get schedules => _schedules;
  List<TaskItem> get tasks => _tasks;
  List<MemoItem> get memos => _memos;
  PlanningSyncStatus get syncStatus => _syncStatus;
  int get totalCount => _schedules.length + _tasks.length + _memos.length;
  int get activeMemoCount => _memos.where((memo) => !memo.isArchived).length;

  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchSchedules(),
        _repository.fetchTasks(),
        _repository.fetchMemos(),
        _repository.fetchSyncStatus(),
      ]);
      _schedules = results[0] as List<ScheduleItem>;
      _tasks = results[1] as List<TaskItem>;
      _memos = results[2] as List<MemoItem>;
      _syncStatus = results[3] as PlanningSyncStatus;
      _lastUpdatedAt = DateTime.now();
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createItem({
    required CaptureItemKind kind,
    required String title,
    DateTime? startAt,
    DateTime? endAt,
    DateTime? dueAt,
    String? location,
    int? durationMinutes,
    String? listId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (kind) {
        case CaptureItemKind.schedule:
          await _repository.createSchedule(
            title: title,
            startAt: startAt,
            endAt: endAt,
            location: location,
            durationMinutes: durationMinutes,
          );
        case CaptureItemKind.task:
          await _repository.createTask(
            title: title,
            plannedStartAt: startAt,
            dueAt: dueAt,
            location: location,
            plannedDurationMinutes: durationMinutes,
          );
        case CaptureItemKind.memo:
          await _repository.createMemo(
            title: title,
            listId: listId,
            estimatedDurationMinutes: durationMinutes,
          );
      }
      await refresh();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> setMemoArchived({
    required String memoId,
    required bool archived,
  }) async {
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.setMemoArchived(memoId: memoId, archived: archived);
      await refresh();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    }
  }

  Future<void> syncNow() async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _syncStatus = await _repository.runSync();
      await refresh();
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }
}
