import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:overview_client/app/app.dart';
import 'package:overview_client/app/app_router.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/launcher/launcher_shortcut_service.dart';
import 'package:overview_client/app/notifications/notification_service.dart';
import 'package:overview_client/app/planning/planning_repository.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('covers the core navigation and capture flow', (tester) async {
    final planningRepository = FakePlanningRepository();

    await tester.pumpWidget(
      OverviewApp(
        repository: planningRepository,
        authRepository: FakeAuthRepository(),
        notificationService: FakeNotificationService(),
        launcherShortcutService: FakeLauncherShortcutService(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week at a glance'), findsOneWidget);

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();

    expect(find.text('Add anything fast'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Integration memo');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to your planning list.'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Integration memo'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Account and sync settings'), findsOneWidget);
    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'integration@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'Password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Account session is ready.'), findsOneWidget);
    expect(find.text('integration@example.com'), findsOneWidget);
  });

  testWidgets('launches directly into capture from launcher shortcut', (
    tester,
  ) async {
    final shortcutService = FakeLauncherShortcutService();

    await tester.pumpWidget(
      OverviewApp(
        initialRoute: AppRouter.homeRoute,
        repository: FakePlanningRepository(),
        authRepository: FakeAuthRepository(),
        notificationService: FakeNotificationService(),
        launcherShortcutService: shortcutService,
      ),
    );
    await tester.pumpAndSettle();

    shortcutService.trigger('shortcut_capture');
    await tester.pumpAndSettle();

    expect(find.text('Add anything fast'), findsOneWidget);
  });
}
