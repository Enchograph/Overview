enum PlanningItemType { schedule, task, memo }

enum PlanningStatus { active, done, cancelled, archived }

enum TaskStatus { todo, inProgress, done, cancelled }

enum SyncState { localOnly, pendingPush, synced, pendingDelete, conflict }

enum PlanningSyncPhase { idle, syncing, success, blocked, failed }

class PlanningSyncStatus {
  const PlanningSyncStatus({
    required this.phase,
    required this.isRemoteEnabled,
    required this.pendingOperationCount,
    required this.pendingItemCount,
    required this.conflictItemCount,
    this.lastAttemptAt,
    this.lastSuccessAt,
    this.lastError,
  });

  factory PlanningSyncStatus.initial({required bool isRemoteEnabled}) {
    return PlanningSyncStatus(
      phase: PlanningSyncPhase.idle,
      isRemoteEnabled: isRemoteEnabled,
      pendingOperationCount: 0,
      pendingItemCount: 0,
      conflictItemCount: 0,
    );
  }

  final PlanningSyncPhase phase;
  final bool isRemoteEnabled;
  final int pendingOperationCount;
  final int pendingItemCount;
  final int conflictItemCount;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String? lastError;

  bool get hasPendingWork => pendingOperationCount > 0 || pendingItemCount > 0;

  PlanningSyncStatus copyWith({
    PlanningSyncPhase? phase,
    bool? isRemoteEnabled,
    int? pendingOperationCount,
    int? pendingItemCount,
    int? conflictItemCount,
    DateTime? lastAttemptAt,
    bool clearLastAttemptAt = false,
    DateTime? lastSuccessAt,
    bool clearLastSuccessAt = false,
    String? lastError,
    bool clearLastError = false,
  }) {
    return PlanningSyncStatus(
      phase: phase ?? this.phase,
      isRemoteEnabled: isRemoteEnabled ?? this.isRemoteEnabled,
      pendingOperationCount: pendingOperationCount ?? this.pendingOperationCount,
      pendingItemCount: pendingItemCount ?? this.pendingItemCount,
      conflictItemCount: conflictItemCount ?? this.conflictItemCount,
      lastAttemptAt: clearLastAttemptAt
          ? null
          : lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: clearLastSuccessAt
          ? null
          : lastSuccessAt ?? this.lastSuccessAt,
      lastError: clearLastError ? null : lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phase': planningSyncPhaseApiValue(phase),
      'isRemoteEnabled': isRemoteEnabled,
      'pendingOperationCount': pendingOperationCount,
      'pendingItemCount': pendingItemCount,
      'conflictItemCount': conflictItemCount,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastSuccessAt': lastSuccessAt?.toIso8601String(),
      'lastError': lastError,
    };
  }

  factory PlanningSyncStatus.fromJson(Map<String, dynamic> json) {
    return PlanningSyncStatus(
      phase: parsePlanningSyncPhase(json['phase'] as String?),
      isRemoteEnabled: json['isRemoteEnabled'] as bool? ?? false,
      pendingOperationCount: json['pendingOperationCount'] as int? ?? 0,
      pendingItemCount: json['pendingItemCount'] as int? ?? 0,
      conflictItemCount: json['conflictItemCount'] as int? ?? 0,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      lastSuccessAt: json['lastSuccessAt'] == null
          ? null
          : DateTime.parse(json['lastSuccessAt'] as String),
      lastError: json['lastError'] as String?,
    );
  }
}

class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.title,
    required this.startAt,
    this.endAt,
    this.description,
    this.location,
    this.timezone,
    this.durationMinutes,
    this.status = PlanningStatus.active,
    this.syncState = SyncState.synced,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    return ScheduleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      startAt: DateTime.parse(json['startAt'] as String),
      endAt: json['endAt'] == null
          ? null
          : DateTime.parse(json['endAt'] as String),
      description: json['description'] as String?,
      location: json['location'] as String?,
      timezone: json['timezone'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      status: parsePlanningStatus(json['status'] as String?),
      syncState: parseSyncState(json['syncState'] as String?),
    );
  }

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime? endAt;
  final String? description;
  final String? location;
  final String? timezone;
  final int? durationMinutes;
  final PlanningStatus status;
  final SyncState syncState;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startAt': startAt.toIso8601String(),
      'endAt': endAt?.toIso8601String(),
      'description': description,
      'location': location,
      'timezone': timezone,
      'durationMinutes': durationMinutes,
      'status': planningStatusApiValue(status),
      'syncState': syncStateApiValue(syncState),
    };
  }
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.plannedStartAt,
    required this.dueAt,
    this.plannedEndAt,
    this.description,
    this.location,
    this.timezone,
    this.plannedDurationMinutes,
    this.status = TaskStatus.todo,
    this.completionAt,
    this.syncState = SyncState.synced,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      plannedStartAt: DateTime.parse(json['plannedStartAt'] as String),
      dueAt: DateTime.parse(json['dueAt'] as String),
      plannedEndAt: json['plannedEndAt'] == null
          ? null
          : DateTime.parse(json['plannedEndAt'] as String),
      description: json['description'] as String?,
      location: json['location'] as String?,
      timezone: json['timezone'] as String?,
      plannedDurationMinutes: json['plannedDurationMinutes'] as int?,
      status: parseTaskStatus(json['status'] as String?),
      completionAt: json['completionAt'] == null
          ? null
          : DateTime.parse(json['completionAt'] as String),
      syncState: parseSyncState(json['syncState'] as String?),
    );
  }

  final String id;
  final String title;
  final DateTime plannedStartAt;
  final DateTime dueAt;
  final DateTime? plannedEndAt;
  final String? description;
  final String? location;
  final String? timezone;
  final int? plannedDurationMinutes;
  final TaskStatus status;
  final DateTime? completionAt;
  final SyncState syncState;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'plannedStartAt': plannedStartAt.toIso8601String(),
      'dueAt': dueAt.toIso8601String(),
      'plannedEndAt': plannedEndAt?.toIso8601String(),
      'description': description,
      'location': location,
      'timezone': timezone,
      'plannedDurationMinutes': plannedDurationMinutes,
      'status': taskStatusApiValue(status),
      'completionAt': completionAt?.toIso8601String(),
      'syncState': syncStateApiValue(syncState),
    };
  }
}

class MemoItem {
  const MemoItem({
    required this.id,
    required this.title,
    required this.listId,
    this.description,
    this.timezone,
    this.estimatedDurationMinutes,
    this.sortOrder,
    this.status = PlanningStatus.active,
    this.archivedAt,
    this.syncState = SyncState.synced,
  });

  factory MemoItem.fromJson(Map<String, dynamic> json) {
    return MemoItem(
      id: json['id'] as String,
      title: json['title'] as String,
      listId: json['listId'] as String,
      description: json['description'] as String?,
      timezone: json['timezone'] as String?,
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int?,
      sortOrder: json['sortOrder'] as int?,
      status: parsePlanningStatus(json['status'] as String?),
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
      syncState: parseSyncState(json['syncState'] as String?),
    );
  }

  final String id;
  final String title;
  final String listId;
  final String? description;
  final String? timezone;
  final int? estimatedDurationMinutes;
  final int? sortOrder;
  final PlanningStatus status;
  final DateTime? archivedAt;
  final SyncState syncState;

  bool get isArchived => status == PlanningStatus.archived;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'listId': listId,
      'description': description,
      'timezone': timezone,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      'sortOrder': sortOrder,
      'status': planningStatusApiValue(status),
      'archivedAt': archivedAt?.toIso8601String(),
      'syncState': syncStateApiValue(syncState),
    };
  }
}

PlanningStatus parsePlanningStatus(String? value) {
  switch (value) {
    case 'done':
      return PlanningStatus.done;
    case 'cancelled':
      return PlanningStatus.cancelled;
    case 'archived':
      return PlanningStatus.archived;
    case 'active':
    default:
      return PlanningStatus.active;
  }
}

TaskStatus parseTaskStatus(String? value) {
  switch (value) {
    case 'in_progress':
      return TaskStatus.inProgress;
    case 'done':
      return TaskStatus.done;
    case 'cancelled':
      return TaskStatus.cancelled;
    case 'todo':
    default:
      return TaskStatus.todo;
  }
}

String planningStatusApiValue(PlanningStatus status) {
  switch (status) {
    case PlanningStatus.active:
      return 'active';
    case PlanningStatus.done:
      return 'done';
    case PlanningStatus.cancelled:
      return 'cancelled';
    case PlanningStatus.archived:
      return 'archived';
  }
}

String taskStatusApiValue(TaskStatus status) {
  switch (status) {
    case TaskStatus.todo:
      return 'todo';
    case TaskStatus.inProgress:
      return 'in_progress';
    case TaskStatus.done:
      return 'done';
    case TaskStatus.cancelled:
      return 'cancelled';
  }
}

SyncState parseSyncState(String? value) {
  switch (value) {
    case 'local_only':
      return SyncState.localOnly;
    case 'pending_push':
      return SyncState.pendingPush;
    case 'pending_delete':
      return SyncState.pendingDelete;
    case 'conflict':
      return SyncState.conflict;
    case 'synced':
    default:
      return SyncState.synced;
  }
}

String syncStateApiValue(SyncState state) {
  switch (state) {
    case SyncState.localOnly:
      return 'local_only';
    case SyncState.pendingPush:
      return 'pending_push';
    case SyncState.synced:
      return 'synced';
    case SyncState.pendingDelete:
      return 'pending_delete';
    case SyncState.conflict:
      return 'conflict';
  }
}

PlanningSyncPhase parsePlanningSyncPhase(String? value) {
  switch (value) {
    case 'syncing':
      return PlanningSyncPhase.syncing;
    case 'success':
      return PlanningSyncPhase.success;
    case 'blocked':
      return PlanningSyncPhase.blocked;
    case 'failed':
      return PlanningSyncPhase.failed;
    case 'idle':
    default:
      return PlanningSyncPhase.idle;
  }
}

String planningSyncPhaseApiValue(PlanningSyncPhase phase) {
  switch (phase) {
    case PlanningSyncPhase.idle:
      return 'idle';
    case PlanningSyncPhase.syncing:
      return 'syncing';
    case PlanningSyncPhase.success:
      return 'success';
    case PlanningSyncPhase.blocked:
      return 'blocked';
    case PlanningSyncPhase.failed:
      return 'failed';
  }
}
