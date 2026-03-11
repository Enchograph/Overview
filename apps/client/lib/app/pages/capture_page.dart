import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'page_section.dart';

class CapturePage extends StatelessWidget {
  const CapturePage({required this.onOpenAi, super.key});

  final VoidCallback onOpenAi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PageSection(
      title: l10n.captureHeadline,
      description: l10n.captureBody,
      highlights: [
        l10n.captureHighlightTask,
        l10n.captureHighlightSchedule,
        l10n.captureHighlightNote,
      ],
      primaryActionLabel: l10n.aiShortcut,
      onPrimaryAction: onOpenAi,
    );
  }
}
