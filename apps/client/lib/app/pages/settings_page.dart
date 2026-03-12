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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletLayout = constraints.maxWidth >= 900;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isTabletLayout
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SettingsPrimaryColumn(
                              headline: l10n.settingsHeadline,
                              body: l10n.settingsBody,
                              onOpenSync: onOpenSync,
                              onOpenAuth: onOpenAuth,
                              syncLabel: l10n.syncShortcut,
                              authLabel: l10n.authShortcut,
                              authStatusTitle: l10n.authStatusTitle,
                              authStatusBody: !authStore.isRemoteEnabled
                                  ? l10n.authUnavailableBody
                                  : session == null
                                      ? l10n.authSignedOutBody
                                      : l10n.authSignedInSummary(session.email),
                              authLogoutLabel: l10n.authLogoutAction,
                              onLogout:
                                  session == null ? null : authStore.logout,
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: _SettingsSecondaryColumn(
                              dataSourceTitle: l10n.settingsDataSourceTitle,
                              dataSourceBody: const String.fromEnvironment(
                                          'OVERVIEW_API_BASE_URL')
                                      .isEmpty
                                  ? l10n.settingsDataSourceMock
                                  : l10n.settingsDataSourceRemote,
                              dataSummaryTitle: l10n.settingsDataSummaryTitle,
                              dataSummaryBody: l10n.settingsDataSummaryBody(
                                store.schedules.length,
                                store.tasks.length,
                                store.memos.length,
                              ),
                              notificationsTitle: l10n.notificationsTitle,
                              notificationsBody: _notificationStatusLabel(
                                l10n,
                                notificationStore.permissionStatus,
                              ),
                              notificationsEnableLabel:
                                  l10n.notificationsEnableAction,
                              notificationsTestLabel:
                                  l10n.notificationsTestAction,
                              notificationsLoading: notificationStore.isLoading,
                              onRequestPermission:
                                  notificationStore.requestPermission,
                              onSendTest:
                                  notificationStore.sendTestNotification,
                              notificationError: notificationStore.errorMessage,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SettingsPrimaryColumn(
                            headline: l10n.settingsHeadline,
                            body: l10n.settingsBody,
                            onOpenSync: onOpenSync,
                            onOpenAuth: onOpenAuth,
                            syncLabel: l10n.syncShortcut,
                            authLabel: l10n.authShortcut,
                            authStatusTitle: l10n.authStatusTitle,
                            authStatusBody: !authStore.isRemoteEnabled
                                ? l10n.authUnavailableBody
                                : session == null
                                    ? l10n.authSignedOutBody
                                    : l10n.authSignedInSummary(session.email),
                            authLogoutLabel: l10n.authLogoutAction,
                            onLogout: session == null ? null : authStore.logout,
                          ),
                          const SizedBox(height: 12),
                          _SettingsSecondaryColumn(
                            dataSourceTitle: l10n.settingsDataSourceTitle,
                            dataSourceBody: const String.fromEnvironment(
                                        'OVERVIEW_API_BASE_URL')
                                    .isEmpty
                                ? l10n.settingsDataSourceMock
                                : l10n.settingsDataSourceRemote,
                            dataSummaryTitle: l10n.settingsDataSummaryTitle,
                            dataSummaryBody: l10n.settingsDataSummaryBody(
                              store.schedules.length,
                              store.tasks.length,
                              store.memos.length,
                            ),
                            notificationsTitle: l10n.notificationsTitle,
                            notificationsBody: _notificationStatusLabel(
                              l10n,
                              notificationStore.permissionStatus,
                            ),
                            notificationsEnableLabel:
                                l10n.notificationsEnableAction,
                            notificationsTestLabel:
                                l10n.notificationsTestAction,
                            notificationsLoading: notificationStore.isLoading,
                            onRequestPermission:
                                notificationStore.requestPermission,
                            onSendTest: notificationStore.sendTestNotification,
                            notificationError: notificationStore.errorMessage,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        );
      },
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

class _SettingsPrimaryColumn extends StatelessWidget {
  const _SettingsPrimaryColumn({
    required this.headline,
    required this.body,
    required this.onOpenSync,
    required this.onOpenAuth,
    required this.syncLabel,
    required this.authLabel,
    required this.authStatusTitle,
    required this.authStatusBody,
    required this.authLogoutLabel,
    required this.onLogout,
  });

  final String headline;
  final String body;
  final VoidCallback onOpenSync;
  final VoidCallback onOpenAuth;
  final String syncLabel;
  final String authLabel;
  final String authStatusTitle;
  final String authStatusBody;
  final String authLogoutLabel;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(headline, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: onOpenSync,
          icon: const Icon(Icons.sync_outlined),
          label: Text(syncLabel),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: onOpenAuth,
          icon: const Icon(Icons.person_outline),
          label: Text(authLabel),
        ),
        const SizedBox(height: 24),
        Card(
          child: ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: Text(authStatusTitle),
            subtitle: Text(authStatusBody),
            trailing: onLogout == null
                ? null
                : TextButton(
                    onPressed: onLogout,
                    child: Text(authLogoutLabel),
                  ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSecondaryColumn extends StatelessWidget {
  const _SettingsSecondaryColumn({
    required this.dataSourceTitle,
    required this.dataSourceBody,
    required this.dataSummaryTitle,
    required this.dataSummaryBody,
    required this.notificationsTitle,
    required this.notificationsBody,
    required this.notificationsEnableLabel,
    required this.notificationsTestLabel,
    required this.notificationsLoading,
    required this.onRequestPermission,
    required this.onSendTest,
    required this.notificationError,
  });

  final String dataSourceTitle;
  final String dataSourceBody;
  final String dataSummaryTitle;
  final String dataSummaryBody;
  final String notificationsTitle;
  final String notificationsBody;
  final String notificationsEnableLabel;
  final String notificationsTestLabel;
  final bool notificationsLoading;
  final Future<void> Function() onRequestPermission;
  final Future<void> Function() onSendTest;
  final String? notificationError;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: Text(dataSourceTitle),
            subtitle: Text(dataSourceBody),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.dataset_outlined),
            title: Text(dataSummaryTitle),
            subtitle: Text(dataSummaryBody),
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
                  title: Text(notificationsTitle),
                  subtitle: Text(notificationsBody),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.tonal(
                      onPressed:
                          notificationsLoading ? null : onRequestPermission,
                      child: Text(notificationsEnableLabel),
                    ),
                    FilledButton(
                      onPressed: notificationsLoading ? null : onSendTest,
                      child: Text(notificationsTestLabel),
                    ),
                  ],
                ),
                if (notificationError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    notificationError!,
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
}
