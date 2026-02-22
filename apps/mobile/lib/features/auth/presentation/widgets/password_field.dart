import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Reusable password input field with show/hide toggle (eye icon).
/// Used on both login and signup screens.
///
/// By default the widget manages its own obscure state internally.
/// Pass [obscureText] + [onToggleObscure] to hand control to the parent —
/// useful when one eye icon must synchronise multiple fields (signup).
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.textInputAction = TextInputAction.done,
    this.onFieldSubmitted,
    this.showVisibilityToggle = true,
    this.obscureText,
    this.onToggleObscure,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  /// Whether to show the eye icon. Defaults to true.
  final bool showVisibilityToggle;

  /// External obscure value. When non-null the widget uses this instead of
  /// its own internal state. Must be paired with [onToggleObscure].
  final bool? obscureText;

  /// Called when the eye icon is tapped in externally-controlled mode.
  final VoidCallback? onToggleObscure;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _internalObscured = true;

  bool get _obscured => widget.obscureText ?? _internalObscured;

  void _toggle() {
    if (widget.onToggleObscure != null) {
      widget.onToggleObscure!();
    } else {
      setState(() => _internalObscured = !_internalObscured);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        suffixIcon: widget.showVisibilityToggle
            ? IconButton(
                icon: Icon(
                  _obscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: _toggle,
              )
            : null,
      ),
    );
  }
}
