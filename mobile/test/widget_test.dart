import 'package:flutter_test/flutter_test.dart';
import 'package:pcelinjak_mobile/services/api_client.dart';
import 'package:pcelinjak_mobile/main.dart';
import 'package:pcelinjak_mobile/screens/auth_screen.dart';

void main() {
  testWidgets('App builds', (tester) async {
    await tester.pumpWidget(PcelinjakApp(api: ApiClient(), startHome: false));
    await tester.pump();
    expect(find.byType(AuthScreen), findsOneWidget);
  });
}
