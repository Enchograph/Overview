import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:overview_client/app/app.dart';
import 'package:overview_client/app/ai/ai_repository.dart';
import 'package:overview_client/app/ai/speech_input_service.dart';
import 'package:overview_client/app/app_router.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/notifications/notification_service.dart';
import 'package:overview_client/app/planning/planning_repository.dart';

void main() {
  Widget buildTestApp({
    String initialRoute = AppRouter.homeRoute,
    PlanningRepository? repository,
    AuthRepository? authRepository,
    AiRepository? aiRepository,
    SpeechInputService? speechInputService,
    NotificationService? notificationService,
  }) {
    return OverviewApp(
      initialRoute: initialRoute,
      repository: repository ?? FakePlanningRepository(),
      authRepository: authRepository,
      aiRepository: aiRepository,
      speechInputService: speechInputService,
      notificationService: notificationService ?? FakeNotificationService(),
    );
  }

  Future<void> pumpAdaptiveApp(
    WidgetTester tester, {
    Size size = const Size(400, 900),
    String initialRoute = AppRouter.homeRoute,
    PlanningRepository? repository,
    AuthRepository? authRepository,
    AiRepository? aiRepository,
    SpeechInputService? speechInputService,
    NotificationService? notificationService,
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
        aiRepository: aiRepository,
        speechInputService: speechInputService,
        notificationService: notificationService,
      ),
    );
  }

  testWidgets('renders default week tab and shell navigation', (tester) async {
    final repository = FakePlanningRepository();

    await pumpAdaptiveApp(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(find.text('Week'), findsNWidgets(2));
    expect(find.text('Week at a glance'), findsOneWidget);
    expect(find.text('Design review'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Wire planning screens'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Wire planning screens'), findsOneWidget);

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes and memos'), findsOneWidget);
    expect(find.text('Ask for final icon set'), findsOneWidget);
  });

  testWidgets('switches to Chinese locale from app bar action', (tester) async {
    await pumpAdaptiveApp(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch language'));
    await tester.pumpAndSettle();

    expect(find.text('周视图'), findsNWidgets(2));
    expect(find.text('本周总览'), findsOneWidget);
    expect(find.text('设计评审'), findsNothing);
  });

  testWidgets('starts from settings route and opens sync page', (tester) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.settingsRoute,
      authRepository: FakeAuthRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNWidgets(2));
    expect(find.text('View sync'), findsOneWidget);
    expect(find.text('Open account'), findsOneWidget);

    await tester.tap(find.text('View sync'));
    await tester.pumpAndSettle();

    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Sync overview'), findsOneWidget);
    expect(find.text('Pending queue'), findsOneWidget);
  });

  testWidgets('creates a memo from capture page', (tester) async {
    final repository = FakePlanningRepository();

    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.captureRoute,
      repository: repository,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Memo').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Prepare launch notes');
    await tester.tap(find.text('Save item'));
    await tester.pumpAndSettle();
    expect(find.text('Saved to your planning list.'), findsOneWidget);

    final memos = await repository.fetchMemos();
    expect(memos.any((memo) => memo.title == 'Prepare launch notes'), isTrue);
  });

  testWidgets('opens auth page and logs in from settings', (tester) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.settingsRoute,
      authRepository: FakeAuthRepository(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open account'));
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Email'),
      'user@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Password'),
      'Password123',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Account session is ready.'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
  });

  testWidgets('parses capture text with ai and applies suggestion',
      (tester) async {
    final repository = FakePlanningRepository();

    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.captureRoute,
      repository: repository,
      aiRepository: FakeAiRepository(
        suggestion: const AiSuggestion(
          suggestedType: AiSuggestionType.memo,
          title: 'Buy cat food',
          confidence: 0.91,
          requiresConfirmation: ['listId'],
          extracted: {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '记得买猫粮');
    await tester.tap(find.text('Parse with AI'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('AI suggestion'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('AI suggests a Memo: Buy cat food'), findsOneWidget);

    final applyButton = find.widgetWithText(
      FilledButton,
      'Confirm and create',
    );
    await tester.scrollUntilVisible(
      applyButton,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(applyButton);
    await tester.pumpAndSettle();
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    final memos = await repository.fetchMemos();
    expect(memos.any((memo) => memo.title == 'Buy cat food'), isTrue);
  });

  testWidgets('asks ai question from ai route', (tester) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.aiRoute,
      aiRepository: FakeAiRepository(
        answer: const AiAnswer(
          answer: 'Start with Design review, then clear the memo inbox.',
          referencedItemCount: 2,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Question'),
      'What should I focus on tomorrow?',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ask AI'));
    await tester.pumpAndSettle();

    expect(find.text('AI answer'), findsOneWidget);
    expect(
      find.text('Start with Design review, then clear the memo inbox.'),
      findsOneWidget,
    );
    expect(find.text('Referenced 2 planning items.'), findsOneWidget);
  });

  testWidgets('shows localized ai auth error on ai route', (tester) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.aiRoute,
      aiRepository: FakeAiRepository(
        failure: const AiRepositoryException(
          code: AiErrorCode.authorizationRequired,
          message: 'Authorization required',
          statusCode: 401,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Question'),
      'What should I focus on tomorrow?',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Ask AI'));
    await tester.pumpAndSettle();

    expect(find.text('Log in again before using AI features.'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('captures voice input and triggers ai parsing', (tester) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.captureRoute,
      aiRepository: FakeAiRepository(
        suggestion: const AiSuggestion(
          suggestedType: AiSuggestionType.task,
          title: 'Prepare board update',
          confidence: 0.86,
          requiresConfirmation: ['dueAt'],
          extracted: {'dueAt': '2026-03-14T09:00:00.000Z'},
        ),
      ),
      speechInputService: FakeSpeechInputService(
        recordedAudio: const RecordedAudio(
          bytes: [1, 2, 3],
          mimeType: 'audio/wav',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Record voice'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Stop recording'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('AI suggestion'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Prepare board update'), findsWidgets);
    expect(find.text('AI suggestion'), findsOneWidget);
    expect(find.text('Confirm and create'), findsOneWidget);
  });

  testWidgets(
      'shows localized azure transcription config error on capture page', (
    tester,
  ) async {
    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.captureRoute,
      aiRepository: FakeAiRepository(
        failure: const AiRepositoryException(
          code: AiErrorCode.azureSpeechNotConfigured,
          message: 'Voice transcription requires Azure Speech configuration.',
          statusCode: 503,
        ),
      ),
      speechInputService: FakeSpeechInputService(),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Record voice'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Stop recording'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Voice transcription is not configured on the server yet.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.text('Voice transcription is not configured on the server yet.'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, 'Record again'), findsOneWidget);
  });

  testWidgets('shows notification controls and triggers test notification', (
    tester,
  ) async {
    final notificationService = FakeNotificationService(
      permissionStatus: NotificationPermissionStatus.denied,
    );

    await pumpAdaptiveApp(
      tester,
      initialRoute: AppRouter.settingsRoute,
      authRepository: FakeAuthRepository(),
      notificationService: notificationService,
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Enable notifications'),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('Notifications'), findsOneWidget);
    expect(
      find.text(
          'Notifications are disabled. Enable them to receive local reminders.'),
      findsOneWidget,
    );

    final testButton = find.widgetWithText(
      FilledButton,
      'Send test notification',
    );
    await tester.ensureVisible(testButton);
    await tester.pumpAndSettle();
    await tester.tap(testButton);
    await tester.pumpAndSettle();

    expect(notificationService.testNotificationShown, isTrue);
  });

  testWidgets('uses tablet navigation rail and keeps week summary visible', (
    tester,
  ) async {
    await pumpAdaptiveApp(
      tester,
      size: const Size(960, 1280),
      repository: FakePlanningRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Planning summary'), findsOneWidget);
    expect(find.text('Schedules'), findsOneWidget);
    expect(find.text('Tasks'), findsOneWidget);
  });

  testWidgets('shows settings tablet cards without extra navigation', (
    tester,
  ) async {
    await pumpAdaptiveApp(
      tester,
      size: const Size(960, 1280),
      initialRoute: AppRouter.settingsRoute,
      authRepository: FakeAuthRepository(),
      notificationService: FakeNotificationService(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Account status'), findsOneWidget);
    expect(find.text('Data source'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
  });

  testWidgets('shows notes summary and memo list on tablet landscape', (
    tester,
  ) async {
    await pumpAdaptiveApp(
      tester,
      size: const Size(1280, 800),
      initialRoute: AppRouter.notesRoute,
      repository: FakePlanningRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Memo inbox'), findsOneWidget);
    expect(find.text('Ask for final icon set'), findsOneWidget);
    expect(find.text('Draft onboarding copy'), findsOneWidget);
  });

  testWidgets(
      'shows explicit refresh actions on desktop-sized week and settings pages',
      (
    tester,
  ) async {
    await pumpAdaptiveApp(
      tester,
      size: const Size(1440, 900),
      repository: FakePlanningRepository(),
      authRepository: FakeAuthRepository(),
      notificationService: FakeNotificationService(),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Refresh data'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Refresh data'), findsOneWidget);
  });
}
