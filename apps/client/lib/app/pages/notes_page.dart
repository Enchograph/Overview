import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'page_section.dart';

class NotesPage extends StatelessWidget {
  const NotesPage({required this.onOpenAi, super.key});

  final VoidCallback onOpenAi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PageSection(
      title: l10n.notesHeadline,
      description: l10n.notesBody,
      highlights: [
        l10n.notesHighlightInbox,
        l10n.notesHighlightMemo,
        l10n.notesHighlightReview,
      ],
      primaryActionLabel: l10n.aiShortcut,
      onPrimaryAction: onOpenAi,
    );
  }
}
