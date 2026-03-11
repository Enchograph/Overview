import 'package:flutter_test/flutter_test.dart';

import 'package:overview_client/main.dart';

void main() {
  testWidgets('renders default week tab and shell navigation', (tester) async {
    await tester.pumpWidget(const OverviewApp());

    expect(find.text('Week'), findsNWidgets(2));
    expect(find.text('Week at a glance'), findsOneWidget);

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
}
