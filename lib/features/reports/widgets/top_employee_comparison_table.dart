import 'package:flutter/material.dart';

import '../../../core/services/DataModels/branch_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Top Employee Comparison" card — every branch's employees pooled
/// and ranked together by revenue generated, with each row tagged by
/// branch, so it reads as one league table rather than per-branch
/// mini-lists. Row layout follows `PnlMonthlyComparisonTable` (header
/// row, divider, one data row per item — however many `items[]` the
/// API sends).
class TopEmployeeComparisonTable extends StatelessWidget {
  final TopEmployeeComparisonSection section;
  final String currencySymbol;

  const TopEmployeeComparisonTable({
    super.key,
    required this.section,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final items = section.items;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(section.title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (items.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.emoji_events_outlined,
              title: 'No Employee Data Yet',
              message: 'Top performers across branches will appear once data is available.',
              height: 140,
            )
          else
            Column(
              children: [
                const _HeaderRow(),
                Divider(color: AppColors.divider, height: 18),
                for (int i = 0; i < items.length; i++) ...[
                  _DataRow(item: items[i], currencySymbol: currencySymbol),
                  if (i != items.length - 1) Divider(color: AppColors.divider, height: 18),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );
    return Row(
      children: [
        const SizedBox(width: 28),
        Expanded(flex: 4, child: Text('Employee', style: style)),
        Expanded(flex: 3, child: Text('Branch', style: style)),
        Expanded(
          flex: 3,
          child: Text('Revenue', textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final TopEmployeeComparisonItem item;
  final String currencySymbol;

  const _DataRow({required this.item, required this.currencySymbol});

  Color _rankColor() {
    switch (item.rank) {
      case 1:
        return const Color(0xFFC9A227); // gold
      case 2:
        return const Color(0xFF9AA0A6); // silver
      case 3:
        return const Color(0xFFB5651D); // bronze
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '#${item.rank}',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: _rankColor(),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            item.employeeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            item.branchName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            CurrencyUtils.format(item.revenue, symbol: currencySymbol),
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
