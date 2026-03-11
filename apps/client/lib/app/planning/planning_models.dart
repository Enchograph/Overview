enum PlanningItemType { schedule, task, memo }

enum PlanningStatus { active, done, cancelled, archived }

enum TaskStatus { todo, inProgress, done, cancelled }

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

  bool get isArchived => status == PlanningStatus.archived;
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
