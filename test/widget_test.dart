import 'package:flutter_test/flutter_test.dart';

import 'package:app_ps4timer/src/app.dart';

void main() {
  testWidgets('shows the PS4 Timer Manager shell', (WidgetTester tester) async {
    final AppController controller = AppController.test();
    addTearDown(controller.dispose);

    await tester.pumpWidget(Ps4TimerApp(controller: controller));
    await tester.pump();

    expect(find.text('PS4 Timer Manager'), findsOneWidget);
    expect(
        find.text('No devices yet. Add a device to start managing the shop.'),
        findsOneWidget);
  });
}
