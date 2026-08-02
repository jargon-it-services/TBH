import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'staff_card_shimmer.dart';

/// Loading state for `StaffListPage` — same shape as
/// [ServiceListShimmer].
class StaffListShimmer extends StatelessWidget {
  const StaffListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) => const StaffCardShimmer(),
    );
  }
}
