import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'expense_card_shimmer.dart';

/// Loading state for `ExpenseListPage` — same shape as
/// [ServiceListShimmer].
class ExpenseListShimmer extends StatelessWidget {
  const ExpenseListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) => const ExpenseCardShimmer(),
    );
  }
}
