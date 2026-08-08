import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_fonts.dart';

/// Loading placeholder for `BranchPerformanceReportPage`: segment row,
/// overview card, branch performance card, the three comparison
/// charts, top employee table, export buttons. Same building blocks as
/// `PnlReportShimmer` / `RevenueExpenseReportShimmer` — no branch
/// dropdown row, since this report doesn't have one.
class BranchPerformanceReportShimmer extends StatelessWidget {
  const BranchPerformanceReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(width: double.infinity, height: 42, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 120, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 300, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _twoUpRowShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 220, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 220, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _exportRowShimmer(),
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

Widget _twoUpRowShimmer() {
  return Row(
    children: [
      Expanded(child: _block(width: double.infinity, height: 200, radius: AppRadius.large)),
      const SizedBox(width: AppSpacing.horizontalMedium),
      Expanded(child: _block(width: double.infinity, height: 200, radius: AppRadius.large)),
    ],
  );
}

Widget _exportRowShimmer() {
  return Row(
    children: [
      Expanded(child: _block(width: double.infinity, height: 46, radius: AppRadius.medium)),
      const SizedBox(width: AppSpacing.horizontalMedium),
      Expanded(child: _block(width: double.infinity, height: 46, radius: AppRadius.medium)),
    ],
  );
}
