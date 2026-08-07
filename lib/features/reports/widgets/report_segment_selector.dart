import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payment_mode_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Segment toggle — "Today / This Week / This Month / 3M / 6M / 12M /
/// Custom" — driven by `meta.periods[]`. Shared by all three report
/// screens (PnL, Payment Mode, Revenue & Expense) via [ReportFilterBar];
/// not used standalone by any page, so if a fourth report needs the
/// same toggle it should go through `ReportFilterBar` too rather than
/// calling this directly. Seven segments don't fit a phone-width pill
/// row the way a 4-tab layout would, so this scrolls horizontally.
class ReportSegmentSelector extends StatelessWidget {
  final List<PnlPeriodOption> periods;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  const ReportSegmentSelector({
    super.key,
    required this.periods,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final period in periods)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _SegmentChip(
                label: period.label,
                isActive: period.key == selectedKey,
                onTap: () {
                  // "Custom" must stay tappable even while already the
                  // active segment -- that's the only way to reopen
                  // the date range picker and choose a *different*
                  // range once one is already set.
                  if (period.key != selectedKey || period.key == 'custom') {
                    onChanged(period.key);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SegmentChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: isActive ? AppColors.textOnPrimary : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
