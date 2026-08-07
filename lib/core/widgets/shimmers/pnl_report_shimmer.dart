import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';

/// Loading placeholder for `PnlReportPage`, shown while the first
/// `/reports/pnl` call is in flight. Mirrors `DashboardShimmer`'s shape
/// (same base `Shimmer.fromColors` wrapper, same card skeleton style)
/// so this reads as one more screen in the same app rather than a
/// bespoke loading state.
class PnlReportShimmer extends StatelessWidget {
  const PnlReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterBarShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _summaryCardsShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _cardShimmer(height: 260),
          const SizedBox(height: AppSpacing.verticalLarge),
          _cardShimmer(height: 300),
          const SizedBox(height: AppSpacing.verticalLarge),
          _cardShimmer(height: 220),
          const SizedBox(height: AppSpacing.verticalLarge),
          _exportButtonsShimmer(),
        ],
      ),
    );
  }
}

Widget _shimmer({required Widget child}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: child,
  );
}

Widget _block({required double width, required double height, double radius = 8}) {
  return _shimmer(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}

Widget _filterBarShimmer() {
  return Row(
    children: [
      Expanded(
        flex: 3,
        child: _block(width: double.infinity, height: 44, radius: AppRadius.large),
      ),
      const SizedBox(width: AppSpacing.horizontalMedium),
      Expanded(
        flex: 2,
        child: _block(width: double.infinity, height: 44, radius: AppRadius.medium),
      ),
    ],
  );
}

Widget _summaryCardsShimmer() {
  return Row(
    children: List.generate(3, (index) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : AppSpacing.horizontalSmall),
          child: _block(width: double.infinity, height: 78, radius: AppRadius.large),
        ),
      );
    }),
  );
}

Widget _cardShimmer({required double height}) {
  return _block(width: double.infinity, height: height, radius: AppRadius.large);
}

Widget _exportButtonsShimmer() {
  return Row(
    children: [
      Expanded(
        child: _block(width: double.infinity, height: 46, radius: AppRadius.medium),
      ),
      const SizedBox(width: AppSpacing.horizontalMedium),
      Expanded(
        child: _block(width: double.infinity, height: 46, radius: AppRadius.medium),
      ),
    ],
  );
}
