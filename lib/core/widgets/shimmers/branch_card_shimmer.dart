import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Shimmer placeholder for one Branch List card — same card shell
/// (radius, border, shadow) as [InsightsCardShimmer] so the loading
/// state matches the loaded [BranchCard] shape (name + address lines,
/// a type/status row) instead of the revenue-card layout that widget
/// was built for.
class BranchCardShimmer extends StatelessWidget {
  const BranchCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.border,
        highlightColor: AppColors.border.withOpacity(0.4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _circle(size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _line(width: 150, height: 16),
                  const SizedBox(height: 8),
                  _line(width: double.infinity, height: 12),
                  const SizedBox(height: 6),
                  _line(width: 120, height: 12),
                  const SizedBox(height: 10),
                  _line(width: 70, height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line({required double width, required double height}) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(6),
        ),
      );

  Widget _circle({required double size}) => Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.border,
        ),
      );
}
