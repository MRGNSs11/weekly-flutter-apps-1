import 'package:flutter_test/flutter_test.dart';
import 'package:ses_kaydedici/main.dart';

void main() {
  testWidgets('deneme ekranı açılıyor, Kaydet düğmesi var', (tester) async {
    await tester.pumpWidget(const DenemeUygulamasi());
    expect(find.text('Kaydet'), findsOneWidget);
    expect(find.text('Durdur'), findsOneWidget);
  });
}
