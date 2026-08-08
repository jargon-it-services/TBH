import 'package:flutter/material.dart';

import '../../../core/services/DataModels/branch_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/card_wrapper.dart';
import 'report_metric_tile.dart';

/// "All Branches Overview" card — the combined Revenue and Profit
/// across every branch for the selected period, plus overall Growth
/// against the API-named comparison period (`comparison_label`, e.g.
/// "vs last month"). Same signed-delta styling as
/// `RevenueExpenseSummaryCards` / `PaymentModeTotalCard`, just laid
/// out as one wide card with three columns instead of stacked tiles.
class BranchOverviewCard extends StatelessWidget {
  final BranchOverviewSummary overview;
  final String currencySymbol;

  const BranchOverviewCard({
    super.key,
    required this.overview,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = overview.growthPercent >= 0;
    final deltaColor = isPositive ? AppColors.success : AppColors.error;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(overview.title, style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.verticalMedium),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ReportMetricTile(
                  label: 'Revenue',
                  value: CurrencyUtils.format(overview.revenue, symbol: currencySymbol),
                ),
              ),
              Expanded(
                child: ReportMetricTile(
                  label: 'Profit',
                  value: CurrencyUtils.format(overview.profit, symbol: currencySymbol),
                ),
              ),
              Expanded(
                child: ReportMetricTile(
                  label: 'Growth',
                  value: "${isPositive ? '+' : ''}${overview.growthPercent.toStringAsFixed(1)}%",
                  valueColor: deltaColor,
                  caption: overview.comparisonLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


