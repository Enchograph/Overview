import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class SyncRoute extends StatelessWidget {
  const SyncRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
              leading: const Icon(Icons.cloud_done_outlined),
              title: Text(l10n.syncStatusTitle),
              subtitle: Text(l10n.syncStatusSubtitle),
            ),
          ),
        ],
      ),
    );
  }
}
