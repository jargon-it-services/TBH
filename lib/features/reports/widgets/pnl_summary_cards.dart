import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

/// Revenue / Expenses / Profit cards shown at the top of the P&L
/// report — same 3-figure snapshot the reference design shows, laid
/// out as three equal cards in a row. Profit is highlighted in
/// [AppColors.success] (or [AppColors.error] if the account is
/// operating at a loss) so it reads as the headline figure.
class PnlSummaryCards extends StatelessWidget {
  final PnlSummary summary;
  final String currencySymbol;

  const PnlSummaryCards({
    super.key,
    required this.summary,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final profitColor =
        summary.profit >= 0 ? AppColors.success : AppColors.error;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Revenue',
            value: CurrencyUtils.format(summary.revenue, symbol: currencySymbol),
            valueColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalSmall),
        Expanded(
          child: _SummaryTile(
            label: 'Expenses',
            value: CurrencyUtils.format(summary.expenses, symbol: currencySymbol),
            valueColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalSmall),
        Expanded(
          child: _SummaryTile(
            label: 'Profit',
            value: CurrencyUtils.format(summary.profit, symbol: currencySymbol),
            valueColor: profitColor,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryTile({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.h3.copyWith(fontSize: 15, color: valueColor),
          ),
        ],
      ),
    );
  }
}
