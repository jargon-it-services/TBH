import 'package:flutter/material.dart';

import '../../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Revenue / Expenses / Net Profit cards, each showing its own signed
/// delta against `summary.comparisonLabel` (e.g. "+12.5% vs
/// yesterday"). Unlike `PnlSummaryCards` (which shows plain figures),
/// every card here carries its own trend indicator, matching the
/// reference design.
class RevenueExpenseSummaryCards extends StatelessWidget {
  final RevenueExpenseSummary summary;
  final String currencySymbol;

  const RevenueExpenseSummaryCards({
    super.key,
    required this.summary,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Revenue',
            value: CurrencyUtils.format(summary.revenue, symbol: currencySymbol),
            changePercent: summary.revenueChangePercent,
            comparisonLabel: summary.comparisonLabel,
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalSmall),
        Expanded(
          child: _SummaryTile(
            label: 'Expenses',
            value: CurrencyUtils.format(summary.expenses, symbol: currencySymbol),
            changePercent: summary.expensesChangePercent,
            comparisonLabel: summary.comparisonLabel,
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalSmall),
        Expanded(
          child: _SummaryTile(
            label: 'Net Profit',
            value: CurrencyUtils.format(summary.netProfit, symbol: currencySymbol),
            changePercent: summary.netProfitChangePercent,
            comparisonLabel: summary.comparisonLabel,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final double changePercent;
  final String comparisonLabel;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.changePercent,
    required this.comparisonLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = changePercent >= 0;
    final deltaColor = isPositive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.horizontalSmall,
        vertical: AppSpacing.verticalMedium,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5)),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: deltaColor,
              ),
              const SizedBox(width: 1),
              Flexible(
                child: Text(
                  "${changePercent.abs().toStringAsFixed(1)}% $comparisonLabel",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: deltaColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
