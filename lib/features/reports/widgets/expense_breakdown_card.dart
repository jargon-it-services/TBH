import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Expense Breakdown" card — donut chart plus a legend that shows
/// both the percentage share and the actual amount per category,
/// built the same way `PnlExpenseCategoriesChart` builds its
/// percent-only version.
class ExpenseBreakdownCard extends StatelessWidget {
  final ExpenseBreakdown breakdown;
  final String currencySymbol;

  const ExpenseBreakdownCard({
    super.key,
    required this.breakdown,
    required this.currencySymbol,
  });

  static const List<Color> _sliceColors = [
    AppColors.primary,
    AppColors.secondary,
    Color(0xFF4CAF50),
    Color(0xFFFFC107),
    Color(0xFF9C27B0),
    Color(0xFF9E9E9E),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
  ];

  @override
  Widget build(BuildContext context) {
    final items = breakdown.items;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(breakdown.title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (items.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.donut_large_outlined,
              title: 'No Expenses Yet',
              message: 'A category-wise breakdown will appear once expenses are recorded.',
              height: 180,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Semantics(
                  label: _donutSummary(items),
                  child: ExcludeSemantics(
                    child: SizedBox(
                      height: 150,
                      width: 150,
                      child: PieChart(
                        PieChartData(
                          centerSpaceRadius: 42,
                          sectionsSpace: 2,
                          sections: List.generate(items.length, (index) {
                            final item = items[index];
                            return PieChartSectionData(
                              value: item.percent,
                              color: _sliceColors[index % _sliceColors.length],
                              radius: 42,
                              showTitle: false,
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(items.length, (index) {
                      final item = items[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              height: 9,
                              width: 9,
                              decoration: BoxDecoration(
                                color: _sliceColors[index % _sliceColors.length],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.label,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  CurrencyUtils.format(item.amount, symbol: currencySymbol),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  "${item.percent.toStringAsFixed(0)}%",
                                  style: AppTextStyles.caption,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Text equivalent of the donut chart, for screen readers — the
  /// legend already carries this as real `Text`, but the chart node
  /// itself was previously unlabeled.
  String _donutSummary(List<ExpenseBreakdownItem> items) {
    if (items.isEmpty) return 'Expense breakdown chart, no data.';
    final parts = items.map((i) => '${i.label} ${i.percent.toStringAsFixed(0)} percent');
    return 'Expense breakdown: ${parts.join(', ')}.';
  }
}
