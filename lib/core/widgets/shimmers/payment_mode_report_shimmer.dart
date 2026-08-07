import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/app_fonts.dart';

/// Loading placeholder for `PaymentModeReportPage`, shape-matched to
/// its real layout: scrollable segment row, branch dropdown, total
/// card, three mode bars, donut card, transaction-count row. Same
/// `Shimmer.fromColors` building blocks as `PnlReportShimmer`.
class PaymentModeReportShimmer extends StatelessWidget {
  const PaymentModeReportShimmer({super.key});

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
          _block(width: double.infinity, height: 110, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 220, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 260, radius: AppRadius.large),
          const SizedBox(height: AppSpacing.verticalLarge),
          _block(width: double.infinity, height: 100, radius: AppRadius.large),
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
