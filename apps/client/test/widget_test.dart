import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:overview_client/app/app.dart';
import 'package:overview_client/app/app_router.dart';
import 'package:overview_client/app/auth/auth_repository.dart';
import 'package:overview_client/app/planning/planning_repository.dart';

void main() {
  testWidgets('renders default week tab and shell navigation', (tester) async {
    final repository = FakePlanningRepository();

    await tester.pumpWidget(
      OverviewApp(repository: repository),
    );
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
    await tester.pumpWidget(
      OverviewApp(repository: FakePlanningRepository()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch language'));
    await tester.pumpAndSettle();

    expect(find.text('周视图'), findsNWidgets(2));
    expect(find.text('本周总览'), findsOneWidget);
    expect(find.text('设计评审'), findsNothing);
  });

  testWidgets('starts from settings route and opens sync page', (tester) async {
    await tester.pumpWidget(
      OverviewApp(
        initialRoute: AppRouter.settingsRoute,
        repository: FakePlanningRepository(),
        authRepository: FakeAuthRepository(),
      ),
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

    await tester.pumpWidget(
      OverviewApp(
        initialRoute: AppRouter.captureRoute,
        repository: repository,
      ),
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
    await tester.pumpWidget(
      OverviewApp(
        initialRoute: AppRouter.settingsRoute,
        repository: FakePlanningRepository(),
        authRepository: FakeAuthRepository(),
      ),
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
}
