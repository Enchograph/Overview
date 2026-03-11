import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class AiRoute extends StatelessWidget {
  const AiRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aiTitle)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            l10n.aiBody,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.start,
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.auto_awesome_outlined),
              title: Text(l10n.aiShortcut),
              subtitle: Text(l10n.aiCta),
            ),
          ),
        ],
      ),
    );
  }
}
