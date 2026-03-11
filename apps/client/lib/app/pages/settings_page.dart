import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../planning/planning_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.onOpenSync, super.key});

  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          l10n.settingsHeadline,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.settingsBody,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onOpenSync,
          icon: const Icon(Icons.sync_outlined),
          label: Text(l10n.syncShortcut),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(l10n.settingsDataSourceTitle),
            subtitle: Text(
              const String.fromEnvironment('OVERVIEW_API_BASE_URL').isEmpty
                  ? l10n.settingsDataSourceMock
                  : l10n.settingsDataSourceRemote,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.dataset_outlined),
            title: Text(l10n.settingsDataSummaryTitle),
            subtitle: Text(
              l10n.settingsDataSummaryBody(
                store.schedules.length,
                store.tasks.length,
                store.memos.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
