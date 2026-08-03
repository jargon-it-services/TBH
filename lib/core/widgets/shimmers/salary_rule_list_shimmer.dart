import 'package:flutter/material.dart';

import '../../theme/app_fonts.dart';
import 'salary_rule_card_shimmer.dart';

/// Loading state for `SalaryRuleListPage` — same shape as
/// [ServiceListShimmer].
class SalaryRuleListShimmer extends StatelessWidget {
  const SalaryRuleListShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppSpacing.verticalMedium),
      itemBuilder: (_, index) => const SalaryRuleCardShimmer(),
    );
  }
}
