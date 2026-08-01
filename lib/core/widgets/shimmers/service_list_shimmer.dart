import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'service_card_shimmer.dart';

/// Loading state for `ServiceListPage` — same `ListView.separated` +
/// fixed item-count shape as [BranchListShimmer].
class ServiceListShimmer extends StatelessWidget {
  const ServiceListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) => const ServiceCardShimmer(),
    );
  }
}
