import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:asagong_flutter/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('IntroScreen to LoginScreen transition test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // 1. Verify that the IntroScreen is shown first.
    expect(find.text('로딩 중입니다...'), findsOneWidget);
    expect(find.text('asagong'), findsOneWidget);

    // 2. Wait for the delay (1 second in IntroScreen + navigation transition)
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Verify that it has transitioned to the LoginScreen.
    expect(find.text('이메일 주소'), findsOneWidget);
    expect(find.text('비밀번호'), findsOneWidget);
    expect(find.text('로그인'), findsOneWidget);
  });
}
