import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../auth/auth_scope.dart';
import '../notifications/notification_scope.dart';
import '../notifications/notification_service.dart';
import '../planning/planning_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.onOpenSync,
    required this.onOpenAuth,
    super.key,
  });

  final VoidCallback onOpenSync;
  final VoidCallback onOpenAuth;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final store = PlanningScope.of(context);
    final authStore = AuthScope.of(context);
    final notificationStore = NotificationScope.of(context);
    final session = authStore.session;

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
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenAuth,
          icon: const Icon(Icons.person_outline),
          label: Text(l10n.authShortcut),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(l10n.authStatusTitle),
            subtitle: Text(
              !authStore.isRemoteEnabled
                  ? l10n.authUnavailableBody
                  : session == null
                      ? l10n.authSignedOutBody
                      : l10n.authSignedInSummary(session.email),
            ),
            trailing: session == null
                ? null
                : TextButton(
                    onPressed: authStore.logout,
                    child: Text(l10n.authLogoutAction),
                  ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.notificationsTitle),
                  subtitle: Text(
                    _notificationStatusLabel(
                      l10n,
                      notificationStore.permissionStatus,
                    ),
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed: notificationStore.isLoading
                          ? null
                          : notificationStore.requestPermission,
                      child: Text(l10n.notificationsEnableAction),
                    ),
                    FilledButton(
                      onPressed: notificationStore.isLoading
                          ? null
                          : notificationStore.sendTestNotification,
                      child: Text(l10n.notificationsTestAction),
                    ),
                  ],
                ),
                if (notificationStore.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    notificationStore.errorMessage!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _notificationStatusLabel(
    AppLocalizations l10n,
    NotificationPermissionStatus status,
  ) {
    switch (status) {
      case NotificationPermissionStatus.granted:
        return l10n.notificationsEnabledBody;
      case NotificationPermissionStatus.denied:
        return l10n.notificationsDisabledBody;
      case NotificationPermissionStatus.unsupported:
        return l10n.notificationsUnsupportedBody;
      case NotificationPermissionStatus.unknown:
        return l10n.notificationsUnknownBody;
    }
  }
}
