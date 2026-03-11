import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../planning/planning_models.dart';
import '../planning/planning_scope.dart';

class WeekPage extends StatelessWidget {
  const WeekPage({required this.onOpenCapture, super.key});

  final VoidCallback onOpenCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.weekHeadline, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(l10n.weekBody, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenCapture,
            icon: const Icon(Icons.add_circle_outline),
            label: Text(l10n.captureShortcut),
          ),
          const SizedBox(height: 24),
          _SummaryCard(
            title: l10n.weekSummaryTitle,
            subtitle: l10n.weekSummaryBody(store.schedules.length, store.tasks.length),
            trailing: store.lastUpdatedAt == null
                ? l10n.dataStatusIdle
                : l10n.dataStatusUpdated(_formatTimestamp(store.lastUpdatedAt!)),
          ),
          const SizedBox(height: 16),
          if (store.isLoading) const LinearProgressIndicator(),
          if (store.errorMessage != null) ...[
            const SizedBox(height: 16),
            _ErrorCard(
              message: store.errorMessage!,
              actionLabel: l10n.retryAction,
              onRetry: store.refresh,
            ),
          ],
          const SizedBox(height: 16),
          _SectionTitle(title: l10n.scheduleSectionTitle),
          const SizedBox(height: 8),
          if (store.schedules.isEmpty)
            _EmptyCard(message: l10n.scheduleEmpty)
          else
            for (final schedule in store.schedules) ...[
              _ScheduleCard(schedule: schedule),
              const SizedBox(height: 12),
            ],
          const SizedBox(height: 16),
          _SectionTitle(title: l10n.taskSectionTitle),
          const SizedBox(height: 8),
          if (store.tasks.isEmpty)
            _EmptyCard(message: l10n.taskEmpty)
          else
            for (final task in store.tasks) ...[
              _TaskCard(task: task),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}/${value.day} $hour:$minute';
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.insights_outlined),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          trailing,
          textAlign: TextAlign.end,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: Theme.of(context).textTheme.titleLarge);
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.inbox_outlined),
        title: Text(message),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final String message;
  final String actionLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.error_outline),
        title: Text(message),
        trailing: TextButton(
          onPressed: onRetry,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({required this.schedule});

  final ScheduleItem schedule;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(schedule.title),
        subtitle: Text(
          '${schedule.startAt.month}/${schedule.startAt.day} '
          '${schedule.startAt.hour.toString().padLeft(2, '0')}:'
          '${schedule.startAt.minute.toString().padLeft(2, '0')}'
          '${schedule.location == null ? '' : ' · ${schedule.location}'}',
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          switch (task.status) {
            TaskStatus.inProgress => Icons.timelapse_outlined,
            TaskStatus.done => Icons.check_circle_outline,
            TaskStatus.cancelled => Icons.cancel_outlined,
            TaskStatus.todo => Icons.radio_button_unchecked,
          },
        ),
        title: Text(task.title),
        subtitle: Text(
          '${task.plannedStartAt.month}/${task.plannedStartAt.day} '
          '${task.plannedStartAt.hour.toString().padLeft(2, '0')}:'
          '${task.plannedStartAt.minute.toString().padLeft(2, '0')}'
          ' · ${task.dueAt.month}/${task.dueAt.day} ${context.l10n.taskDueLabel}',
        ),
      ),
    );
  }
}
