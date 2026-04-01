import 'package:flutter_test/flutter_test.dart';

import 'package:sinhvien_app/app.dart';

void main() {
  testWidgets('home renders with tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const StudentPlannerApp());

    expect(find.text('Lịch'), findsOneWidget);
    expect(find.text('Điểm'), findsOneWidget);
    expect(find.text('Đồng bộ'), findsOneWidget);
    expect(find.text('Tài khoản'), findsOneWidget);
  });
}
