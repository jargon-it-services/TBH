import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// App-wide filled/labeled text field — the standard form input style
/// used across Login, Forgot Password, and Registration.
///
/// Originally lived as `RegistrationTextField` inside the registration
/// feature, but it carries no registration-specific logic (just label,
/// icon, validator, obscureText, etc.) and was already being imported by
/// LoginPage and ForgotPasswordPage. Moved here and renamed to reflect
/// that it's a common, feature-independent building block, not
/// something registration owns.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.initialValue,
    this.onChanged,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final IconData icon;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        keyboardType: keyboardType,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        readOnly: readOnly,
        enabled: enabled,
        onTap: onTap,
        validator: validator,
        textCapitalization: textCapitalization,
        style: AppTextStyles.body,
        decoration: InputDecoration(
          filled: true,
          fillColor: AppColors.primary.withOpacity(0.1),
          prefixIcon: Icon(icon, size: AppIcons.defaultSize),
          suffixIcon: suffixIcon,
          hintText: label,
          hintStyle: const TextStyle(color: Colors.grey),
          errorMaxLines: 2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            borderSide: const BorderSide(color: AppColors.error, width: 1.2),
          ),
        ),
      ),
    );
  }
}
