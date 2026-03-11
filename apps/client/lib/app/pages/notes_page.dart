import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../planning/planning_models.dart';
import '../planning/planning_scope.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({required this.onOpenAi, super.key});

  final VoidCallback onOpenAi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);

    return RefreshIndicator(
      onRefresh: store.refresh,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(l10n.notesHeadline, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text(l10n.notesBody, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onOpenAi,
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(l10n.aiShortcut),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sticky_note_2_outlined),
              title: Text(l10n.notesSummaryTitle),
              subtitle: Text(
                l10n.notesSummaryBody(store.activeMemoCount, store.memos.length),
              ),
            ),
          ),
          if (store.errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: Text(store.errorMessage!),
                trailing: TextButton(
                  onPressed: store.refresh,
                  child: Text(l10n.retryAction),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (store.isLoading) const LinearProgressIndicator(),
          const SizedBox(height: 16),
          if (store.memos.isEmpty)
            Card(
              child: ListTile(
                leading: const Icon(Icons.inbox_outlined),
                title: Text(l10n.memoEmpty),
              ),
            )
          else
            for (final memo in store.memos) ...[
              _MemoCard(memo: memo, onToggle: () {
                store.setMemoArchived(
                  memoId: memo.id,
                  archived: !memo.isArchived,
                );
              }),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _MemoCard extends StatelessWidget {
  const _MemoCard({
    required this.memo,
    required this.onToggle,
  });

  final MemoItem memo;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: ListTile(
        leading: Icon(
          memo.isArchived
              ? Icons.archive_outlined
              : Icons.sticky_note_2_outlined,
        ),
        title: Text(memo.title),
        subtitle: Text(
          memo.isArchived ? l10n.memoArchivedLabel : l10n.memoInboxLabel,
        ),
        trailing: TextButton(
          onPressed: onToggle,
          child: Text(
            memo.isArchived ? l10n.memoRestoreAction : l10n.memoArchiveAction,
          ),
        ),
      ),
    );
  }
}
