import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_fonts.dart';
import 'shimmer_widgets.dart';

class TransactionDetailsShimmer extends StatelessWidget {
  const TransactionDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.verticalSmall),
          _statusCardShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _priceBreakdownShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _infoCardShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _infoCardShimmer(),
          const SizedBox(height: AppSpacing.verticalLarge),
          _notesShimmer(),
        ],
      ),
    );
  }

  // ================= STATUS CARD =================

  Widget _statusCardShimmer() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: const Row(
        children: [
          ShimmerLine(width: 120),
          Spacer(),
          ShimmerChip(width: 50),
          SizedBox(width: AppSpacing.horizontalSmall),
          ShimmerChip(width: 40),
        ],
      ),
    );
  }

  // ================= PRICE =================

  Widget _priceBreakdownShimmer() {
    return _cardWrapper(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLine(width: 140),
          SizedBox(height: AppSpacing.verticalMedium),
          _LabelValueShimmer(),
          SizedBox(height: AppSpacing.verticalSmall),
          _LabelValueShimmer(),
          Divider(height: AppSpacing.verticalLarge),
          _LabelValueShimmer(isBold: true),
        ],
      ),
    );
  }

  // ================= INFO CARD =================

  Widget _infoCardShimmer() {
    return _cardWrapper(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLine(width: 180),
          SizedBox(height: AppSpacing.verticalMedium),
          _InfoRowShimmer(),
          SizedBox(height: AppSpacing.verticalMedium),
          _InfoRowShimmer(),
          SizedBox(height: AppSpacing.verticalMedium),
          _InfoRowShimmer(),
        ],
      ),
    );
  }

  // ================= NOTES =================

  Widget _notesShimmer() {
    return _cardWrapper(
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerLine(width: 100),
          SizedBox(height: AppSpacing.verticalMedium),
          ShimmerLine(width: double.infinity),
          SizedBox(height: 6),
          ShimmerLine(width: double.infinity),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Widget _cardWrapper(Widget child) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

// ================= SMALL SHIMMER PARTS =================

class _InfoRowShimmer extends StatelessWidget {
  const _InfoRowShimmer();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        ShimmerBox(
          width: 20,
          height: 20,
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        SizedBox(width: AppSpacing.horizontalMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerLine(width: 100, height: 10),
              SizedBox(height: 6),
              ShimmerLine(width: double.infinity),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabelValueShimmer extends StatelessWidget {
  final bool isBold;

  const _LabelValueShimmer({this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerLine(width: 120),
        const Spacer(),
        ShimmerLine(width: isBold ? 80 : 60, height: isBold ? 16 : 12),
      ],
    );
  }
}
