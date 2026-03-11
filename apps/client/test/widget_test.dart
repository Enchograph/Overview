import 'package:flutter_test/flutter_test.dart';

import 'package:overview_client/app/app.dart';
import 'package:overview_client/app/app_router.dart';

void main() {
  testWidgets('renders default week tab and shell navigation', (tester) async {
    await tester.pumpWidget(const OverviewApp());

    expect(find.text('Week'), findsNWidgets(2));
    expect(find.text('Week at a glance'), findsOneWidget);
    expect(
      find.text('Plan this week with tasks, schedule blocks, and priorities.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Notes'));
    await tester.pumpAndSettle();

    expect(find.text('Notes and memos'), findsOneWidget);
    expect(find.text('Open AI'), findsOneWidget);
  });

  testWidgets('switches to Chinese locale from app bar action', (tester) async {
    await tester.pumpWidget(const OverviewApp());

    await tester.tap(find.byTooltip('Switch language'));
    await tester.pumpAndSettle();

    expect(find.text('周视图'), findsNWidgets(2));
    expect(find.text('本周总览'), findsOneWidget);
  });

  testWidgets('starts from settings route and opens sync page', (tester) async {
    await tester.pumpWidget(
      const OverviewApp(initialRoute: AppRouter.settingsRoute),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNWidgets(2));
    expect(find.text('View sync'), findsOneWidget);

    await tester.tap(find.text('View sync'));
    await tester.pumpAndSettle();

    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Local-only mode'), findsOneWidget);
  });
}
