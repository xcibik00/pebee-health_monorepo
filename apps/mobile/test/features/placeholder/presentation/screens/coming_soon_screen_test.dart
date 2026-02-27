import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/placeholder/presentation/screens/coming_soon_screen.dart';

import '../../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Future<void> pumpComingSoonScreen(
    WidgetTester tester, {
    String title = 'Test Tab',
  }) async {
    await pumpApp(
      tester,
      child: ComingSoonScreen(title: title),
    );
  }

  group('ComingSoonScreen', () {
    testWidgets('renders coming soon text', (tester) async {
      await pumpComingSoonScreen(tester);

      expect(find.text('dashboard.comingSoon'), findsOneWidget);
    });

    testWidgets('renders construction icon', (tester) async {
      await pumpComingSoonScreen(tester);

      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
    });
  });
}
