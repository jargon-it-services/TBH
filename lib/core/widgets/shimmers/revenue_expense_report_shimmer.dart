import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_fonts.dart';

/// Loading placeholder for `RevenueExpenseReportPage`: scrollable
/// segment row, branch dropdown, 3 summary cards, trend chart, donut
/// card, services list, export buttons. Same building blocks as
/// `PaymentModeReportShimmer` / `PnlReportShimmer`.
class RevenueExpenseReportShimmer extends StatelessWidget {
  const RevenueExpenseReportShimmer({super.key});

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
          _summaryRowShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 240, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 280, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 180, radius: AppRadius.large),
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

Widget _summaryRowShimmer() {
  return Row(
    children: List.generate(3, (index) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: index == 2 ? 0 : AppSpacing.horizontalSmall),
          child: _block(width: double.infinity, height: 84, radius: AppRadius.large),
        ),
      );
    }),
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
