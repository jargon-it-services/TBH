import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

/// Generic "nothing here yet" placeholder — an icon, a title, an
/// optional message, and an optional CTA button, with a small
/// fade+slide-in animation.
///
/// Shared across features (Branch list, Revenue trend chart, etc.) —
/// previously this lived inside the old dashboard feature, which meant
/// unrelated screens had to import a dashboard file just to render an
/// empty state. It now lives here in `core/widgets` where any feature
/// can use it.
class AnimatedEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? ctaLabel;
  final VoidCallback? onCtaTap;
  final double height;

  const AnimatedEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.ctaLabel,
    this.onCtaTap,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.page,
              AppSpacing.verticalMedium, // 👈 prevents overflow
            ),
            child: Column(
              children: [
                /// Illustration Circle
                Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withOpacity(0.08),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 10),

                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                if (ctaLabel != null && onCtaTap != null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: onCtaTap,
                    child: Text(ctaLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
