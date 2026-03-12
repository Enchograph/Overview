import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../planning/planning_models.dart';
import '../planning/planning_scope.dart';

class SyncRoute extends StatelessWidget {
  const SyncRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);
    final syncStatus = store.syncStatus;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.syncBody,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(
                syncStatus.isRemoteEnabled
                    ? Icons.cloud_done_outlined
                    : Icons.cloud_off_outlined,
              ),
              title: Text(l10n.syncStatusTitle),
              subtitle: Text(
                '${_phaseLabel(l10n, syncStatus.phase)} · '
                '${syncStatus.isRemoteEnabled ? l10n.syncRemoteEnabled : l10n.syncRemoteDisabled}',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync_problem_outlined),
              title: Text(l10n.syncPendingTitle),
              subtitle: Text(
                l10n.syncPendingBody(
                  syncStatus.pendingOperationCount,
                  syncStatus.pendingItemCount,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.syncStatusSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _StatusRow(
                    label: l10n.syncLastAttemptLabel,
                    value: _formatTimestamp(syncStatus.lastAttemptAt),
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: l10n.syncLastSuccessLabel,
                    value: _formatTimestamp(syncStatus.lastSuccessAt),
                  ),
                  const SizedBox(height: 8),
                  _StatusRow(
                    label: l10n.syncLastErrorLabel,
                    value: syncStatus.lastError ?? l10n.syncStatusPending,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: store.isSyncing ? null : store.syncNow,
            icon: store.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync_outlined),
            label: Text(store.isSyncing ? l10n.syncPhaseSyncing : l10n.syncRunAction),
          ),
        ],
      ),
    );
  }

  String _phaseLabel(AppLocalizations l10n, PlanningSyncPhase phase) {
    switch (phase) {
      case PlanningSyncPhase.idle:
        return l10n.syncPhaseIdle;
      case PlanningSyncPhase.syncing:
        return l10n.syncPhaseSyncing;
      case PlanningSyncPhase.success:
        return l10n.syncPhaseSuccess;
      case PlanningSyncPhase.blocked:
        return l10n.syncPhaseBlocked;
      case PlanningSyncPhase.failed:
        return l10n.syncPhaseFailed;
    }
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final twoDigitMonth = local.month.toString().padLeft(2, '0');
    final twoDigitDay = local.day.toString().padLeft(2, '0');
    final twoDigitHour = local.hour.toString().padLeft(2, '0');
    final twoDigitMinute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$twoDigitMonth-$twoDigitDay '
        '$twoDigitHour:$twoDigitMinute';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
