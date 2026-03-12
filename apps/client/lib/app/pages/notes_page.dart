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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscapeTablet = constraints.maxWidth >= 1100;

        return RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
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
                        const SizedBox(height: 16),
                      ],
                      isLandscapeTablet
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: _NotesSummaryColumn(
                                    headline: l10n.notesHeadline,
                                    body: l10n.notesBody,
                                    aiLabel: l10n.aiShortcut,
                                    onOpenAi: onOpenAi,
                                    summaryTitle: l10n.notesSummaryTitle,
                                    summaryBody: l10n.notesSummaryBody(
                                      store.activeMemoCount,
                                      store.memos.length,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 6,
                                  child: _NotesMemoColumn(
                                    emptyMessage: l10n.memoEmpty,
                                    memos: store.memos,
                                    onToggleMemo: (memo) {
                                      store.setMemoArchived(
                                        memoId: memo.id,
                                        archived: !memo.isArchived,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _NotesSummaryColumn(
                                  headline: l10n.notesHeadline,
                                  body: l10n.notesBody,
                                  aiLabel: l10n.aiShortcut,
                                  onOpenAi: onOpenAi,
                                  summaryTitle: l10n.notesSummaryTitle,
                                  summaryBody: l10n.notesSummaryBody(
                                    store.activeMemoCount,
                                    store.memos.length,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _NotesMemoColumn(
                                  emptyMessage: l10n.memoEmpty,
                                  memos: store.memos,
                                  onToggleMemo: (memo) {
                                    store.setMemoArchived(
                                      memoId: memo.id,
                                      archived: !memo.isArchived,
                                    );
                                  },
                                ),
                              ],
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotesSummaryColumn extends StatelessWidget {
  const _NotesSummaryColumn({
    required this.headline,
    required this.body,
    required this.aiLabel,
    required this.onOpenAi,
    required this.summaryTitle,
    required this.summaryBody,
  });

  final String headline;
  final String body;
  final String aiLabel;
  final VoidCallback onOpenAi;
  final String summaryTitle;
  final String summaryBody;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onOpenAi,
          icon: const Icon(Icons.auto_awesome_outlined),
          label: Text(aiLabel),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sticky_note_2_outlined),
            title: Text(summaryTitle),
            subtitle: Text(summaryBody),
          ),
        ),
      ],
    );
  }
}

class _NotesMemoColumn extends StatelessWidget {
  const _NotesMemoColumn({
    required this.emptyMessage,
    required this.memos,
    required this.onToggleMemo,
  });

  final String emptyMessage;
  final List<MemoItem> memos;
  final ValueChanged<MemoItem> onToggleMemo;

  @override
  Widget build(BuildContext context) {
    if (memos.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.inbox_outlined),
          title: Text(emptyMessage),
        ),
      );
    }

    return Column(
      children: [
        for (final memo in memos) ...[
          _MemoCard(
            memo: memo,
            onToggle: () => onToggleMemo(memo),
          ),
          const SizedBox(height: 12),
        ],
      ],
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
