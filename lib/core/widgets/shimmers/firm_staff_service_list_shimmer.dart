import 'package:flutter/material.dart';
import '../../../core/widgets/shimmers/insights_card_shimmer.dart';

import '../../theme/app_fonts.dart';

class FirmStaffServiceListShimmer extends StatelessWidget {
  const FirmStaffServiceListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) {
        return const InsightsCardShimmer();
      },
    );
  }
}
