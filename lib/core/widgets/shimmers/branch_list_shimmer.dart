import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'branch_card_shimmer.dart';

/// Loading state for [BranchListPage] — a fixed-count
/// `ListView.separated` skeleton.
class BranchListShimmer extends StatelessWidget {
  const BranchListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) => const BranchCardShimmer(),
    );
  }
}
