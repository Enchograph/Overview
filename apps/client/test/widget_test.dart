import 'package:flutter_test/flutter_test.dart';

import 'package:overview_client/main.dart';

void main() {
  testWidgets('renders default week tab', (tester) async {
    await tester.pumpWidget(const OverviewApp());

    expect(find.text('Week'), findsNWidgets(2));
    expect(find.text('Weekly overview will land here.'), findsOneWidget);
  });
}
