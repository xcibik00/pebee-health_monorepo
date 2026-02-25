import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/presentation/screens/signup_screen.dart';
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

  Future<void> pumpSignupScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      child: const SignupScreen(),
      overrides: [
        authNotifierProvider.overrideWith(() => fakeNotifier),
      ],
    );
  }

  /// Fills all form fields with valid data.
  Future<void> fillValidForm(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'John'); // first name
    await tester.enterText(fields.at(1), 'Doe'); // last name
    await tester.enterText(fields.at(2), 'john@example.com'); // email
    await tester.enterText(fields.at(3), 'password123'); // password
    await tester.enterText(fields.at(4), 'password123'); // confirm
  }

  /// Checks both consent checkboxes (Terms & Privacy).
  Future<void> checkBothConsents(WidgetTester tester) async {
    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(0));
    await tester.tap(checkboxes.at(1));
    await tester.pump();
  }

  /// Finds the ElevatedButton and returns whether it is enabled.
  bool isCreateButtonEnabled(WidgetTester tester) {
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'auth.signup.createButton'),
    );
    return button.onPressed != null;
  }

  group('SignupScreen', () {
    testWidgets('renders all expected elements', (tester) async {
      await pumpSignupScreen(tester);

      expect(find.text('auth.signup.title'), findsOneWidget);
      expect(find.text('auth.signup.subtitle'), findsOneWidget);
      expect(find.text('auth.signup.firstNameLabel'), findsOneWidget);
      expect(find.text('auth.signup.lastNameLabel'), findsOneWidget);
      expect(find.text('auth.signup.emailLabel'), findsOneWidget);
      expect(find.text('auth.signup.passwordLabel'), findsOneWidget);
      expect(find.text('auth.signup.confirmPasswordLabel'), findsOneWidget);
      expect(find.text('auth.signup.createButton'), findsOneWidget);
      expect(find.text('auth.signup.signIn'), findsOneWidget);
      // Two consent checkboxes (terms + privacy)
      expect(find.byType(Checkbox), findsNWidgets(2));
    });

    testWidgets('create button disabled initially', (tester) async {
      await pumpSignupScreen(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.pump();

      expect(isCreateButtonEnabled(tester), isFalse);
    });

    testWidgets('create button disabled when first name empty',
        (tester) async {
      await pumpSignupScreen(tester);

      // Fill everything except first name
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'password123');
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.pump();

      expect(isCreateButtonEnabled(tester), isFalse);
    });

    testWidgets('create button enabled when form complete', (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.pump();

      expect(isCreateButtonEnabled(tester), isTrue);
    });

    testWidgets('password too short shows validation error', (tester) async {
      await pumpSignupScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'short'); // < 8 chars
      await tester.enterText(fields.at(4), 'short');
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordTooShort'), findsOneWidget);
    });

    testWidgets('password mismatch shows validation error', (tester) async {
      await pumpSignupScreen(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John');
      await tester.enterText(fields.at(1), 'Doe');
      await tester.enterText(fields.at(2), 'john@example.com');
      await tester.enterText(fields.at(3), 'password123');
      await tester.enterText(fields.at(4), 'different99');
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(find.text('validation.passwordMismatch'), findsOneWidget);
    });

    testWidgets('valid form calls signUp with correct args', (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.signUpCalled, isTrue);
      expect(fakeNotifier.lastSignUpEmail, 'john@example.com');
      expect(fakeNotifier.lastSignUpFirstName, 'John');
      expect(fakeNotifier.lastSignUpLastName, 'Doe');
      // Locale should be 'en' from our EasyLocalization test setup
      expect(fakeNotifier.lastSignUpLocale, 'en');
    });

    testWidgets('successful signup navigates to verification screen',
        (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(find.text('VERIFY_ROUTE'), findsOneWidget);
    });

    testWidgets('error state shows error banner', (tester) async {
      fakeNotifier.signUpError = Exception('Email already exists');

      await pumpSignupScreen(tester);
      await fillValidForm(tester);
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(find.text('auth.signup.error'), findsOneWidget);
    });

    testWidgets('create button disabled when terms checkbox unchecked',
        (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);

      // Only check privacy, leave terms unchecked
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.pump();

      expect(isCreateButtonEnabled(tester), isFalse);
    });

    testWidgets('create button disabled when privacy checkbox unchecked',
        (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);

      // Only check terms, leave privacy unchecked
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.at(0));
      await tester.pump();

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.pump();

      expect(isCreateButtonEnabled(tester), isFalse);
    });

    testWidgets('submit succeeds when both checkboxes checked',
        (tester) async {
      await pumpSignupScreen(tester);
      await fillValidForm(tester);
      await checkBothConsents(tester);

      await tester.ensureVisible(find.text('auth.signup.createButton'));
      await tester.tap(find.text('auth.signup.createButton'));
      await tester.pumpAndSettle();

      expect(fakeNotifier.signUpCalled, isTrue);
    });

    testWidgets('eye icon toggles both password fields', (tester) async {
      await pumpSignupScreen(tester);

      // Both password fields should be obscured by default.
      // Find all EditableText widgets (one per TextFormField).
      final editableTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      );
      // Fields 3 (password) and 4 (confirm) should be obscured
      final passwordField = editableTexts.elementAt(3);
      final confirmField = editableTexts.elementAt(4);
      expect(passwordField.obscureText, isTrue);
      expect(confirmField.obscureText, isTrue);

      // Tap the eye icon (only one, on the first password field)
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now both should be visible
      final updatedTexts = tester.widgetList<EditableText>(
        find.byType(EditableText),
      );
      expect(updatedTexts.elementAt(3).obscureText, isFalse);
      expect(updatedTexts.elementAt(4).obscureText, isFalse);
    });
  });
}
