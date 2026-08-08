import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Loading state for [BranchDetailPage] — a plain skeleton (header
/// block + a handful of info rows), simplified since the Branch
/// Details screen has no chart/trend section to skeleton.
class BranchDetailShimmer extends StatelessWidget {
  const BranchDetailShimmer({super.key});

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
            _box(height: 90, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.verticalLarge),
            _box(width: 140, height: 18),
            const SizedBox(height: AppSpacing.verticalMedium),
            _box(height: 180, radius: AppRadius.large),
            const SizedBox(height: AppSpacing.verticalLarge),
            _box(width: 140, height: 18),
            const SizedBox(height: AppSpacing.verticalMedium),
            _box(height: 140, radius: AppRadius.large),
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
