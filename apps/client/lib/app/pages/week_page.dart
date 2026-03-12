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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLayout = constraints.maxWidth >= 900;
        final isDesktopLayout = constraints.maxWidth >= 1180;
        final content = ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (store.isLoading) const LinearProgressIndicator(),
                    if (store.errorMessage != null) ...[
                      if (store.isLoading) const SizedBox(height: 16),
                      _ErrorCard(
                        message: store.errorMessage!,
                        actionLabel: l10n.retryAction,
                        onRetry: store.refresh,
                      ),
                      const SizedBox(height: 16),
                    ],
                    isTabletLayout
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _WeekPrimaryColumn(
                                  headline: l10n.weekHeadline,
                                  body: l10n.weekBody,
                                  captureLabel: l10n.captureShortcut,
                                  refreshLabel: l10n.refreshAction,
                                  onOpenCapture: onOpenCapture,
                                  onRefresh: store.refresh,
                                  showRefreshAction: isDesktopLayout,
                                  summaryTitle: l10n.weekSummaryTitle,
                                  summaryBody: l10n.weekSummaryBody(
                                    store.schedules.length,
                                    store.tasks.length,
                                  ),
                                  summaryTrailing: store.lastUpdatedAt == null
                                      ? l10n.dataStatusIdle
                                      : l10n.dataStatusUpdated(
                                          _formatTimestamp(
                                              store.lastUpdatedAt!),
                                        ),
                                  scheduleSectionTitle:
                                      l10n.scheduleSectionTitle,
                                  schedules: store.schedules,
                                  scheduleEmpty: l10n.scheduleEmpty,
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: _WeekTaskColumn(
                                  title: l10n.taskSectionTitle,
                                  emptyMessage: l10n.taskEmpty,
                                  tasks: store.tasks,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _WeekPrimaryColumn(
                                headline: l10n.weekHeadline,
                                body: l10n.weekBody,
                                captureLabel: l10n.captureShortcut,
                                refreshLabel: l10n.refreshAction,
                                onOpenCapture: onOpenCapture,
                                onRefresh: store.refresh,
                                showRefreshAction: false,
                                summaryTitle: l10n.weekSummaryTitle,
                                summaryBody: l10n.weekSummaryBody(
                                  store.schedules.length,
                                  store.tasks.length,
                                ),
                                summaryTrailing: store.lastUpdatedAt == null
                                    ? l10n.dataStatusIdle
                                    : l10n.dataStatusUpdated(
                                        _formatTimestamp(store.lastUpdatedAt!),
                                      ),
                                scheduleSectionTitle: l10n.scheduleSectionTitle,
                                schedules: store.schedules,
                                scheduleEmpty: l10n.scheduleEmpty,
                              ),
                              const SizedBox(height: 16),
                              _WeekTaskColumn(
                                title: l10n.taskSectionTitle,
                                emptyMessage: l10n.taskEmpty,
                                tasks: store.tasks,
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),
          ],
        );

        return RefreshIndicator(
          onRefresh: store.refresh,
          child: isDesktopLayout ? Scrollbar(child: content) : content,
        );
      },
    );
  }
}

class _WeekPrimaryColumn extends StatelessWidget {
  const _WeekPrimaryColumn({
    required this.headline,
    required this.body,
    required this.captureLabel,
    required this.refreshLabel,
    required this.onOpenCapture,
    required this.onRefresh,
    required this.showRefreshAction,
    required this.summaryTitle,
    required this.summaryBody,
    required this.summaryTrailing,
    required this.scheduleSectionTitle,
    required this.schedules,
    required this.scheduleEmpty,
  });

  final String headline;
  final String body;
  final String captureLabel;
  final String refreshLabel;
  final VoidCallback onOpenCapture;
  final Future<void> Function() onRefresh;
  final bool showRefreshAction;
  final String summaryTitle;
  final String summaryBody;
  final String summaryTrailing;
  final String scheduleSectionTitle;
  final List<ScheduleItem> schedules;
  final String scheduleEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onOpenCapture,
              icon: const Icon(Icons.add_circle_outline),
              label: Text(captureLabel),
            ),
            if (showRefreshAction)
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_outlined),
                label: Text(refreshLabel),
              ),
          ],
        ),
        const SizedBox(height: 24),
        _SummaryCard(
          title: summaryTitle,
          subtitle: summaryBody,
          trailing: summaryTrailing,
        ),
        const SizedBox(height: 16),
        _SectionTitle(title: scheduleSectionTitle),
        const SizedBox(height: 8),
        if (schedules.isEmpty)
          _EmptyCard(message: scheduleEmpty)
        else
          for (final schedule in schedules) ...[
            _ScheduleCard(schedule: schedule),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _WeekTaskColumn extends StatelessWidget {
  const _WeekTaskColumn({
    required this.title,
    required this.emptyMessage,
    required this.tasks,
  });

  final String title;
  final String emptyMessage;
  final List<TaskItem> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: title),
        const SizedBox(height: 8),
        if (tasks.isEmpty)
          _EmptyCard(message: emptyMessage)
        else
          for (final task in tasks) ...[
            _TaskCard(task: task),
            const SizedBox(height: 12),
          ],
      ],
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
