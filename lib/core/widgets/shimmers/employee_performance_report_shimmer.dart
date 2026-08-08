import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_fonts.dart';

/// Loading placeholder for `EmployeePerformanceReportPage`,
/// shape-matched to its real layout: segment row, branch dropdown,
/// top performer card, search bar, ranking table, export row. Same
/// `Shimmer.fromColors` building blocks as `PaymentModeReportShimmer`
/// / `PnlReportShimmer`.
class EmployeePerformanceReportShimmer extends StatelessWidget {
  const EmployeePerformanceReportShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _block(width: double.infinity, height: 42, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalSmall),
          _block(width: double.infinity, height: 44, radius: AppRadius.medium),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 190, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 44, radius: AppRadius.medium),
          const SizedBox(height: AppSpacing.verticalMedium),
          _block(width: double.infinity, height: 340, radius: AppRadius.large),
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

Widget _exportRowShimmer() {
  return Row(
    children: [
      Expanded(child: _block(width: double.infinity, height: 46, radius: AppRadius.medium)),
      const SizedBox(width: AppSpacing.horizontalMedium),
      Expanded(child: _block(width: double.infinity, height: 46, radius: AppRadius.medium)),
    ],
  );
}
