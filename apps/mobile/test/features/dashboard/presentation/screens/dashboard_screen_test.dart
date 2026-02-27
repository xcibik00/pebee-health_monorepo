import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/providers/auth_provider.dart';
import 'package:pebee_mobile/features/consent/models/user_consent.dart';
import 'package:pebee_mobile/features/consent/providers/consent_provider.dart';
import 'package:pebee_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';

import '../../../../helpers/mocks.dart';
import '../../../../helpers/test_app.dart';

void main() {
  late FakeAuthNotifier fakeNotifier;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    fakeNotifier = FakeAuthNotifier();
  });

  Future<void> pumpDashboardScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const DashboardScreen(),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
        // Override auth state to prevent Supabase.instance access
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        // Provide empty consents to prevent real API calls
        consentsProvider.overrideWith((ref) async => <UserConsent>[]),
        // Prevent consent save attempts that need API client
        hasTermsConsentProvider.overrideWithValue(true),
        hasPrivacyConsentProvider.overrideWithValue(true),
        hasAttConsentProvider.overrideWithValue(true),
      ],
    );
  }

  group('DashboardScreen', () {
    testWidgets('renders greeting header', (tester) async {
      await pumpDashboardScreen(tester);

      // With empty asset loader, .tr(namedArgs) returns the raw key
      expect(find.text('dashboard.greeting'), findsOneWidget);
    });

    testWidgets('renders stat cards', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('dashboard.overallProgress'), findsOneWidget);
      expect(find.text('dashboard.completedExercises'), findsOneWidget);
      expect(find.text('85%'), findsOneWidget);
      expect(find.text('23'), findsOneWidget);
    });

    testWidgets('renders weekly goal card', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('dashboard.weeklyGoal'), findsOneWidget);
    });

    testWidgets('renders todays exercise section', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('dashboard.todaysExercise'), findsOneWidget);
      expect(find.text('dashboard.exerciseTitle'), findsOneWidget);
      expect(find.text('dashboard.startExercise'), findsOneWidget);
    });

    testWidgets('renders training plan section', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('dashboard.trainingPlan'), findsOneWidget);
    });

    testWidgets('renders exercise level and duration', (tester) async {
      await pumpDashboardScreen(tester);

      expect(find.text('dashboard.exerciseLevel'), findsOneWidget);
      expect(find.text('dashboard.exerciseDuration'), findsOneWidget);
    });
  });
}
