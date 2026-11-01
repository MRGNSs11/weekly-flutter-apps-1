import 'package:flutter_test/flutter_test.dart';
import 'package:kasa_not/main.dart';

void main() {
  testWidgets('deneme ekranı kapalı kasayla açılır', (tester) async {
    await tester.pumpWidget(const DenemeUygulamasi());
    expect(find.textContaining('KASA KAPALI'), findsOneWidget);
  });
}
