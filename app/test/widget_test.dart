import 'package:flutter_test/flutter_test.dart';

import 'package:trendfit/main.dart';

void main() {
  testWidgets('온보딩 화면이 시작 화면으로 뜬다', (WidgetTester tester) async {
    await tester.pumpWidget(const TrendFitApp());

    expect(find.text('TrendFit'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
