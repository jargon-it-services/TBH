import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'shimmer_widgets.dart';

class NotificationListShimmer extends StatelessWidget {
  final int itemCount;

  const NotificationListShimmer({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
      itemCount: itemCount,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, __) => const _NotificationShimmerCard(),
    );
  }
}

class _NotificationShimmerCard extends StatelessWidget {
  const _NotificationShimmerCard();

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
                ShimmerLine(width: 200),
                SizedBox(height: 8),
                ShimmerLine(width: 90, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
