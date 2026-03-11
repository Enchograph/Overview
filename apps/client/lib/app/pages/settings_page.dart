import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'page_section.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({required this.onOpenSync, super.key});

  final VoidCallback onOpenSync;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PageSection(
      title: l10n.settingsHeadline,
      description: l10n.settingsBody,
      highlights: [
        l10n.settingsHighlightAccount,
        l10n.settingsHighlightSync,
        l10n.settingsHighlightDevice,
      ],
      primaryActionLabel: l10n.syncShortcut,
      onPrimaryAction: onOpenSync,
    );
  }
}
