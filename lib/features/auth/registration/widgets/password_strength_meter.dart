import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_fonts.dart';

enum _Strength { empty, weak, medium, strong }

_Strength _scorePassword(String password) {
  if (password.isEmpty) return _Strength.empty;

  int score = 0;
  if (password.length >= 8) score++;
  if (password.length >= 12) score++;
  if (RegExp(r'[A-Z]').hasMatch(password)) score++;
  if (RegExp(r'[0-9]').hasMatch(password)) score++;
  if (RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password)) score++;

  if (score <= 1) return _Strength.weak;
  if (score <= 3) return _Strength.medium;
  return _Strength.strong;
}

class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({super.key, required this.password});

  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = _scorePassword(password);
    if (strength == _Strength.empty) return const SizedBox.shrink();

    final Color color;
    final String label;
    final int filledSegments;

    switch (strength) {
      case _Strength.weak:
        color = AppColors.error;
        label = 'Weak';
        filledSegments = 1;
        break;
      case _Strength.medium:
        color = AppColors.warning;
        label = 'Medium';
        filledSegments = 2;
        break;
      case _Strength.strong:
        color = AppColors.success;
        label = 'Strong';
        filledSegments = 3;
        break;
      case _Strength.empty:
        color = AppColors.textDisabled;
        label = '';
        filledSegments = 0;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.verticalMedium),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: List.generate(3, (i) {
                final filled = i < filledSegments;
                return Expanded(
                  child: Container(
                    height: 5,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: filled
                          ? color
                          : AppColors.textDisabled.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
