import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/data/auth_repository.dart';
import 'package:pebee_mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:pebee_mobile/features/auth/providers/auth_provider.dart';

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

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const LoginScreen(),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
      ],
    );
  }

  group('LoginScreen', () {
    testWidgets('renders all expected elements', (tester) async {
      await pumpLoginScreen(tester);

      expect(find.text('auth.login.title'), findsOneWidget);
      expect(find.text('auth.login.subtitle'), findsOneWidget);
      expect(find.text('auth.login.emailLabel'), findsOneWidget);
      expect(find.text('auth.login.passwordLabel'), findsOneWidget);
      expect(find.text('auth.login.signInButton'), findsOneWidget);
      expect(find.text('auth.login.createAccount'), findsOneWidget);
    });

    testWidgets('empty email shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.emailRequired'), findsOneWidget);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'not-an-email',
      );
      // Fill password so it doesn't fail there
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.emailInvalid'), findsOneWidget);
    });

    testWidgets('empty password shows validation error', (tester) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordRequired'), findsOneWidget);
    });

    testWidgets('valid form calls signIn with correct args', (tester) async {
      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'myPassword1',
      );

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.signInCalled, isTrue);
      expect(fakeNotifier.lastSignInEmail, 'test@example.com');
      expect(fakeNotifier.lastSignInPassword, 'myPassword1');
    });

    testWidgets('error state shows error banner', (tester) async {
      fakeNotifier.signInError = Exception('Invalid credentials');

      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'wrong-password',
      );

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.login.error'), findsOneWidget);
    });

    testWidgets(
        'EmailNotConfirmedException navigates to verification screen',
        (tester) async {
      fakeNotifier.signInError =
          const EmailNotConfirmedException('test@example.com');

      await pumpLoginScreen(tester);

      await tester.enterText(
        find.byType(TextFormField).first,
        'test@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'password123',
      );

      await tester.tap(find.text('auth.login.signInButton'));
      await tester.pumpAndSettle();

      // GoRouter should have navigated to the verification placeholder route
      expect(find.text('VERIFY_ROUTE'), findsOneWidget);
    });
  });
}
