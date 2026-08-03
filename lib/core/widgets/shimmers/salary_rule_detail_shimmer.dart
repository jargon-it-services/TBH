import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Loading state for `SalaryRuleDetailPage` — same skeleton shape as
/// [ServiceDetailShimmer].
class SalaryRuleDetailShimmer extends StatelessWidget {
  const SalaryRuleDetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border,
      highlightColor: AppColors.border.withOpacity(0.4),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _box(height: 100, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.verticalLarge),
            _box(width: 140, height: 18),
            const SizedBox(height: AppSpacing.verticalMedium),
            _box(height: 160, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.verticalLarge),
            _box(height: 100, radius: AppRadius.large),
          ],
        ),
      ),
    );
  }

  Widget _box({
    double width = double.infinity,
    required double height,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
