import 'package:flutter/material.dart';
import 'package:furspeak_ai/config/app_theme.dart';

/// A design-system-compliant text form field wrapper.
///
/// Ensures consistent styling, border radius, and color tokens
/// across all input fields in the app.
class FurInputField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  const FurInputField({
    super.key,
    this.controller,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      style: AppTheme.bodyStyle.copyWith(
        color: AppTheme.textColor,
        fontSize: 15,
      ),
      decoration: AppTheme.inputDecoration(
        label: label,
        prefixIcon: prefixIcon ?? Icons.edit_rounded,
      ).copyWith(
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.surfaceActive,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppTheme.borderRadiusMedium,
          borderSide: const BorderSide(
            color: AppTheme.errorColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
