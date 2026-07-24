import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'shimmer_widgets.dart';

class TransactionListShimmer extends StatelessWidget {
  final int itemCount;

  const TransactionListShimmer({
    super.key,
    this.itemCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, __) => const _TransactionShimmerCard(),
    );
  }
}

class _TransactionShimmerCard extends StatelessWidget {
  const _TransactionShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          ShimmerCircle(size: 44),
          SizedBox(width: AppSpacing.horizontalMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerLine(width: double.infinity, height: 14),
                SizedBox(height: 6),
                ShimmerLine(width: 140),
                SizedBox(height: 4),
                ShimmerLine(width: 100),
                SizedBox(height: 8),
                Row(
                  children: [
                    ShimmerChip(width: 60),
                    SizedBox(width: 6),
                    ShimmerChip(width: 48),
                    SizedBox(width: 6),
                    ShimmerChip(width: 54),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.horizontalMedium),
          ShimmerLine(width: 64, height: 14),
        ],
      ),
    );
  }
}
