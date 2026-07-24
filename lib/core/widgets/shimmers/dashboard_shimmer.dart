import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'shimmer_widgets.dart';

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _quickActionsShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          const SizedBox(height: AppSpacing.verticalLarge),
          _dropdownShimmer(),
          const SizedBox(height: AppSpacing.verticalMedium),
          _chartShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _summaryShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _pieChartShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _insightsListShimmer(),
        ],
      ),
    );
  }
}

/// ------------------------------------------------------------
/// Base shimmer wrapper
/// ------------------------------------------------------------
Widget _shimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: child,
  );
}

/// ------------------------------------------------------------
/// Quick actions row shimmer
/// ------------------------------------------------------------
Widget _quickActionsShimmer() {
  return Row(
    children: List.generate(3, (_) {
      return Expanded(
        child: Column(
          children: [
            _shimmer(
              child: Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _shimmer(
              child: Container(
                height: 10,
                width: 50,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }),
  );
}

/// ------------------------------------------------------------
/// Dropdown shimmer
/// ------------------------------------------------------------
Widget _dropdownShimmer() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// Label shimmer
      // _shimmer(
      //   child: Container(
      //     height: 10,
      //     width: 90,
      //     margin: const EdgeInsets.only(bottom: 6),
      //     color: Colors.white,
      //   ),
      // ),

      /// Dropdown field shimmer
      _shimmer(
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              /// Icon
              Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),

              /// Value text
              Expanded(
                child: Container(
                  height: 12,
                  color: Colors.white,
                ),
              ),

              /// Dropdown arrow
              Container(
                height: 12,
                width: 12,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _chartShimmer() {
  return const ShimmerBox(
    height: 340,
    width: double.infinity,
    borderRadius: BorderRadius.all(Radius.circular(AppRadius.large)),
  );
}

Widget _summaryShimmer() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const ShimmerLine(width: 160, height: 16),
      const SizedBox(height: 12),
      ...List.generate(4, (_) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              ShimmerCircle(size: 14),
              SizedBox(width: 8),
              Expanded(child: ShimmerLine(width: double.infinity)),
              SizedBox(width: 20),
              ShimmerLine(width: 60),
            ],
          ),
        );
      }),
    ],
  );
}

/// ------------------------------------------------------------
/// Revenue contribution pie shimmer
/// ------------------------------------------------------------
Widget _pieChartShimmer() {
  return Column(
    children: [
      _shimmer(
        child: Container(
          height: 180,
          width: 180,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(height: 16),
      ...List.generate(3, (_) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _shimmer(
            child: Row(
              children: [
                Container(
                  height: 10,
                  width: 10,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(height: 10, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Container(height: 10, width: 30, color: Colors.white),
              ],
            ),
          ),
        );
      }),
    ],
  );
}

/// ------------------------------------------------------------
/// Insights cards shimmer
/// ------------------------------------------------------------
Widget _insightsListShimmer() {
  return Column(
    children: List.generate(3, (_) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.verticalLarge),
        child: _shimmer(
          child: Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
          ),
        ),
      );
    }),
  );
}
