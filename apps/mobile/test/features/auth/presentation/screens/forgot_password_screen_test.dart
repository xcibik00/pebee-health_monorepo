import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/presentation/screens/forgot_password_screen.dart';
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

  Future<void> pumpForgotPasswordScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const ForgotPasswordScreen(),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
      ],
    );
  }

  group('ForgotPasswordScreen', () {
    testWidgets('renders all expected elements', (tester) async {
      await pumpForgotPasswordScreen(tester);

      expect(find.text('auth.forgotPassword.title'), findsOneWidget);
      expect(find.text('auth.forgotPassword.subtitle'), findsOneWidget);
      expect(find.text('auth.forgotPassword.emailLabel'), findsOneWidget);
      expect(find.text('auth.forgotPassword.sendButton'), findsOneWidget);
      expect(find.text('auth.forgotPassword.backToLogin'), findsOneWidget);
    });

    testWidgets('empty email shows validation error', (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.tap(find.text('auth.forgotPassword.sendButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.emailRequired'), findsOneWidget);
    });

    testWidgets('invalid email shows validation error', (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.enterText(find.byType(TextFormField), 'notanemail');
      await tester.tap(find.text('auth.forgotPassword.sendButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.emailInvalid'), findsOneWidget);
    });

    testWidgets('valid email calls requestPasswordReset', (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.enterText(
          find.byType(TextFormField), 'john@example.com');
      await tester.tap(find.text('auth.forgotPassword.sendButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.requestPasswordResetCalled, isTrue);
      expect(fakeNotifier.lastResetEmail, 'john@example.com');
    });

    testWidgets('success shows confirmation view', (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.enterText(
          find.byType(TextFormField), 'john@example.com');
      await tester.tap(find.text('auth.forgotPassword.sendButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.forgotPassword.successTitle'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
    });

    testWidgets('error shows error banner', (tester) async {
      fakeNotifier.requestPasswordResetError = Exception('Not found');

      await pumpForgotPasswordScreen(tester);

      await tester.enterText(
          find.byType(TextFormField), 'john@example.com');
      await tester.tap(find.text('auth.forgotPassword.sendButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.forgotPassword.error'), findsOneWidget);
    });

    testWidgets('back to login navigates correctly', (tester) async {
      await pumpForgotPasswordScreen(tester);

      await tester.tap(find.text('auth.forgotPassword.backToLogin'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_ROUTE'), findsOneWidget);
    });
  });
}
