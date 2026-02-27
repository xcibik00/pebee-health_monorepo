import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/dashboard/presentation/widgets/greeting_header.dart';

import '../../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('GreetingHeader', () {
    testWidgets('renders greeting with first name', (tester) async {
      await pumpApp(
        tester,
        child: const GreetingHeader(firstName: 'Olivia'),
      );

      // With empty asset loader, .tr(namedArgs) returns the raw key
      expect(find.text('dashboard.greeting'), findsOneWidget);
    });

    testWidgets('renders avatar with first letter', (tester) async {
      await pumpApp(
        tester,
        child: const GreetingHeader(firstName: 'Olivia'),
      );

      expect(find.text('O'), findsOneWidget);
    });

    testWidgets('handles empty first name gracefully', (tester) async {
      await pumpApp(
        tester,
        child: const GreetingHeader(firstName: ''),
      );

      // Should show '?' as fallback
      expect(find.text('?'), findsOneWidget);
    });
  });
}
