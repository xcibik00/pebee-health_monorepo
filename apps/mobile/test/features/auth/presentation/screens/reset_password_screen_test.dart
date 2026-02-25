import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/presentation/screens/reset_password_screen.dart';
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

  Future<void> pumpResetPasswordScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const ResetPasswordScreen(),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
      ],
    );
  }

  group('ResetPasswordScreen', () {
    testWidgets('renders all expected elements', (tester) async {
      await pumpResetPasswordScreen(tester);

      expect(find.text('auth.resetPassword.title'), findsOneWidget);
      expect(find.text('auth.resetPassword.subtitle'), findsOneWidget);
      expect(find.text('auth.resetPassword.passwordLabel'), findsOneWidget);
      expect(
          find.text('auth.resetPassword.confirmPasswordLabel'), findsOneWidget);
      expect(find.text('auth.resetPassword.resetButton'), findsOneWidget);
    });

    testWidgets('empty password shows validation error', (tester) async {
      await pumpResetPasswordScreen(tester);

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordRequired'), findsOneWidget);
    });

    testWidgets('password too short shows validation error', (tester) async {
      await pumpResetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'short');
      await tester.enterText(fields.at(1), 'short');

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordTooShort'), findsOneWidget);
    });

    testWidgets('password mismatch shows validation error', (tester) async {
      await pumpResetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'different99');

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordMismatch'), findsOneWidget);
    });

    testWidgets('valid form calls updatePassword', (tester) async {
      await pumpResetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newpassword123');
      await tester.enterText(fields.at(1), 'newpassword123');

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.updatePasswordCalled, isTrue);
      expect(fakeNotifier.lastNewPassword, 'newpassword123');
    });

    testWidgets('success shows confirmation view', (tester) async {
      await pumpResetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newpassword123');
      await tester.enterText(fields.at(1), 'newpassword123');

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.resetPassword.successTitle'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('error shows error banner', (tester) async {
      fakeNotifier.updatePasswordError = Exception('Token expired');

      await pumpResetPasswordScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'newpassword123');
      await tester.enterText(fields.at(1), 'newpassword123');

      await tester.tap(find.text('auth.resetPassword.resetButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.resetPassword.error'), findsOneWidget);
    });

    testWidgets('eye icon toggles both password fields', (tester) async {
      await pumpResetPasswordScreen(tester);

      // Both should be obscured by default
      final editableTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      );
      expect(editableTexts.elementAt(0).obscureText, isTrue);
      expect(editableTexts.elementAt(1).obscureText, isTrue);

      // Tap the eye icon
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now both should be visible
      final updatedTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      );
      expect(updatedTexts.elementAt(0).obscureText, isFalse);
      expect(updatedTexts.elementAt(1).obscureText, isFalse);
    });
  });
}
