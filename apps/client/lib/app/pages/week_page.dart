import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'page_section.dart';

class WeekPage extends StatelessWidget {
  const WeekPage({required this.onOpenCapture, super.key});

  final VoidCallback onOpenCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PageSection(
      title: l10n.weekHeadline,
      description: l10n.weekBody,
      highlights: [
        l10n.weekHighlightPlanning,
        l10n.weekHighlightProgress,
        l10n.weekHighlightFocus,
      ],
      primaryActionLabel: l10n.captureShortcut,
      onPrimaryAction: onOpenCapture,
    );
  }
}
