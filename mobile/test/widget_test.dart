import 'package:flutter_test/flutter_test.dart';
import 'package:unicheck_mobile/main.dart';

void main() {
  testWidgets('UniCheck Mobile app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UniCheckMobileApp());

    // Verify app renders title
    expect(find.text('UniCheck'), findsOneWidget);
    expect(find.text('Đăng Nhập'), findsOneWidget);
  });
}
