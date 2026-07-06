import 'package:flutter_test/flutter_test.dart';
import 'package:malas_nulis/main.dart';

void main() {
  testWidgets('App renders without error', (WidgetTester tester) async {
    await tester.pumpWidget(const MalasNulisApp());
    expect(find.text('Registrasi Huruf A (1/26)'), findsOneWidget);
  });
}