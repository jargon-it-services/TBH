import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Pill-style period tabs — "3M / 6M / 12M / Custom" — driven entirely
/// by `meta.periods[]` from the report response, never hardcoded here.
/// Visual style mirrors the dashboard's own period selector (rounded
/// pill row, active tab filled with [AppColors.primary]) so this reads
/// as the same app, just built as its own small widget rather than
/// reaching into the dashboard feature's private widgets.
class PnlPeriodSelector extends StatelessWidget {
  final List<PnlPeriodOption> periods;
  final String selectedKey;
  final ValueChanged<String> onChanged;

  const PnlPeriodSelector({
    super.key,
    required this.periods,
    required this.selectedKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final period in periods)
            Expanded(
              child: _PeriodTab(
                label: period.label,
                isActive: period.key == selectedKey,
                onTap: () {
                  // Every other tab is a no-op re-tap once active, but
                  // "Custom" must stay tappable even while already
                  // selected -- that's the only way to open the date
                  // range picker again and pick a *different* range.
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

class _PeriodTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _PeriodTab({
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
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
