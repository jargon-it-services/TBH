import 'package:flutter/material.dart';

import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/shimmers/shimmer_widgets.dart';

/// Composed the same way `dashboard_shimmer.dart` composes the generic
/// [ShimmerLine]/[ShimmerBox]/[ShimmerCircle] primitives for its own
/// sections -- no new shimmer primitives introduced here, just a
/// layout specific to this screen.
class SubscriptionShimmer extends StatelessWidget {
  const SubscriptionShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        ShimmerBox(
          width: double.infinity,
          height: 64,
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        ShimmerBox(
          width: double.infinity,
          height: 84,
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        ShimmerBox(
          width: double.infinity,
          height: 44,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        const SizedBox(height: AppSpacing.verticalMedium),
        for (var i = 0; i < 3; i++) ...[
          ShimmerBox(
            width: double.infinity,
            height: 220,
            borderRadius: BorderRadius.circular(AppRadius.large),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
        ],
      ],
    );
  }
}
