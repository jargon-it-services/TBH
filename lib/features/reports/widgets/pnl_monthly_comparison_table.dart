import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Monthly Comparison" card — Month / Revenue / Expenses / Profit,
/// one row per month, however many `monthly_comparison.rows[]` the API
/// sends (never a fixed row count).
class PnlMonthlyComparisonTable extends StatelessWidget {
  final PnlMonthlyComparison comparison;
  final String currencySymbol;

  const PnlMonthlyComparisonTable({
    super.key,
    required this.comparison,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final rows = comparison.rows;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.table_rows_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(comparison.title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (rows.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.table_rows_outlined,
              title: 'No Comparison Data Yet',
              message:
                  'A month-by-month comparison will appear once data is available for this period.',
              height: 140,
            )
          else
            Column(
              children: [
                _HeaderRow(),
                Divider(color: AppColors.divider, height: 18),
                for (int i = 0; i < rows.length; i++) ...[
                  _DataRow(row: rows[i], currencySymbol: currencySymbol),
                  if (i != rows.length - 1)
                    Divider(color: AppColors.divider, height: 18),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final style = AppTextStyles.caption.copyWith(
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
    );
    return Row(
      children: [
        Expanded(flex: 2, child: Text('Month', style: style)),
        Expanded(
          flex: 3,
          child: Text('Revenue', textAlign: TextAlign.end, style: style),
        ),
        Expanded(
          flex: 3,
          child: Text('Expenses', textAlign: TextAlign.end, style: style),
        ),
        Expanded(
          flex: 3,
          child: Text('Profit', textAlign: TextAlign.end, style: style),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final PnlMonthlyRow row;
  final String currencySymbol;

  const _DataRow({required this.row, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final profitColor =
        row.profit >= 0 ? AppColors.success : AppColors.error;
    final valueStyle = AppTextStyles.bodySmall.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            row.month,
            style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            CurrencyUtils.format(row.revenue, symbol: currencySymbol),
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            CurrencyUtils.format(row.expenses, symbol: currencySymbol),
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            CurrencyUtils.format(row.profit, symbol: currencySymbol),
            textAlign: TextAlign.end,
            style: valueStyle.copyWith(color: profitColor, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
