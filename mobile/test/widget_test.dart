import 'package:flutter_test/flutter_test.dart';
import 'package:pcelinjak_mobile/services/api_client.dart';
import 'package:pcelinjak_mobile/main.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(PcelinjakApp(api: ApiClient(), startHome: false));
    expect(find.text('Pčelinjak'), findsOneWidget);
  });
}
