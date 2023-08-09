import 'package:flutter_test/flutter_test.dart';

import 'package:smartwatch_poc/main.dart';

void main() {
  testWidgets('App should start with no reminders',
      (WidgetTester tester) async {
    await tester.pumpWidget(const RemindersApp());

    expect(find.text('Lembrete 1'), findsNothing);
    expect(find.text('Lembrete 2'), findsNothing);
  });
}
