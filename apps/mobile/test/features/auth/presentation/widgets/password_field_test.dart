import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pebee_mobile/features/auth/presentation/widgets/password_field.dart';

void main() {
  Widget buildSubject({
    TextEditingController? controller,
    String labelText = 'Password',
    String? hintText,
    bool showVisibilityToggle = true,
    bool? obscureText,
    VoidCallback? onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: PasswordField(
          controller: controller ?? TextEditingController(),
          labelText: labelText,
          hintText: hintText,
          showVisibilityToggle: showVisibilityToggle,
          obscureText: obscureText,
          onToggleObscure: onToggleObscure,
          validator: validator,
        ),
      ),
    );
  }

  group('PasswordField', () {
    testWidgets('renders with label and hint text', (tester) async {
      await tester.pumpWidget(buildSubject(
        labelText: 'Password',
        hintText: 'Enter password',
      ));

      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Enter password'), findsOneWidget);
    });

    testWidgets('text is obscured by default', (tester) async {
      await tester.pumpWidget(buildSubject());

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isTrue);
    });

    testWidgets('tapping eye icon toggles visibility', (tester) async {
      await tester.pumpWidget(buildSubject());

      // Initially obscured — visibility icon shown
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap to reveal
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      // Now visible — visibility_off icon shown
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap again to hide
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    });

    testWidgets('external obscureText overrides internal state',
        (tester) async {
      // obscureText = false means text is visible regardless of internal state
      await tester.pumpWidget(buildSubject(
        obscureText: false,
        onToggleObscure: () {},
      ));

      final editableText =
          tester.widget<EditableText>(find.byType(EditableText));
      expect(editableText.obscureText, isFalse);
    });

    testWidgets('showVisibilityToggle false hides the eye icon',
        (tester) async {
      await tester.pumpWidget(buildSubject(showVisibilityToggle: false));

      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('validator shows error text', (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: PasswordField(
              controller: TextEditingController(),
              labelText: 'Password',
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                return null;
              },
            ),
          ),
        ),
      ));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
    });
  });
}
