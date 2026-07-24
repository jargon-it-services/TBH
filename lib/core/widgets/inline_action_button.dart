import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Small text-only action button used as a text-field's suffix
/// (e.g. "Send OTP", "Verify"). Extracted from ForgotPasswordPage's
/// original `_inlineActionButton` with the exact same styling,
/// typography, padding and interaction behavior.
class InlineActionButton extends StatelessWidget {
  const InlineActionButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: AppColors.secondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
