import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:overview_client/app/app.dart';
import 'package:overview_client/app/app_router.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/launcher/launcher_shortcut_service.dart';
import 'package:overview_client/app/notifications/notification_service.dart';
import 'package:overview_client/app/planning/planning_repository.dart';

Widget buildTestApp({
  String initialRoute = AppRouter.homeRoute,
  PlanningRepository? repository,
  AuthRepository? authRepository,
  NotificationService? notificationService,
  LauncherShortcutService? launcherShortcutService,
}) {
  return OverviewApp(
    initialRoute: initialRoute,
    repository: repository ?? FakePlanningRepository(),
    authRepository: authRepository,
    notificationService: notificationService ?? FakeNotificationService(),
    launcherShortcutService:
        launcherShortcutService ?? FakeLauncherShortcutService(),
  );
}

Future<void> pumpAdaptiveApp(
  WidgetTester tester, {
  Size size = const Size(400, 900),
  String initialRoute = AppRouter.homeRoute,
  PlanningRepository? repository,
  AuthRepository? authRepository,
  NotificationService? notificationService,
  LauncherShortcutService? launcherShortcutService,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    buildTestApp(
      initialRoute: initialRoute,
      repository: repository,
      authRepository: authRepository,
      notificationService: notificationService,
      launcherShortcutService: launcherShortcutService,
    ),
  );
}

void main() {
  testWidgets('covers the main navigation and capture flow', (tester) async {
    final planningRepository = FakePlanningRepository();

    await pumpAdaptiveApp(
      tester,
      repository: planningRepository,
      authRepository: FakeAuthRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Week at a glance'), findsOneWidget);

    await tester.tap(find.text('Capture'));
    await tester.pumpAndSettle();

    expect(find.text('Add anything fast'), findsOneWidget);
    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memo').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Smoke memo');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();

    expect(find.text('Saved to your planning list.'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Smoke memo'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Account and sync settings'), findsOneWidget);
    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'smoke@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'Password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('smoke@example.com'), findsOneWidget);
  });

  testWidgets('opens capture directly from launcher shortcut smoke flow', (
    tester,
  ) async {
    final shortcutService = FakeLauncherShortcutService();

    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.homeRoute,
      repository: FakePlanningRepository(),
      authRepository: FakeAuthRepository(),
      launcherShortcutService: shortcutService,
    );
    await tester.pumpAndSettle();

    shortcutService.trigger('shortcut_capture');
    await tester.pumpAndSettle();

    expect(find.text('Add anything fast'), findsOneWidget);
  });
}
