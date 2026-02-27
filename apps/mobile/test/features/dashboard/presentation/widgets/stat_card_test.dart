import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/dashboard/presentation/widgets/stat_card.dart';

import '../../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('StatCard', () {
    testWidgets('renders label and value', (tester) async {
      await pumpApp(
        tester,
        child: const StatCard(
          label: 'Progress',
          value: '85%',
          valueColor: Colors.purple,
        ),
      );

      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
    });

    testWidgets('applies correct value color', (tester) async {
      await pumpApp(
        tester,
        child: const StatCard(
          label: 'Exercises',
          value: '23',
          valueColor: Colors.orange,
        ),
      );

      final valueWidget = tester.widget<Text>(find.text('23'));
      expect(valueWidget.style?.color, Colors.orange);
    });
  });
}
