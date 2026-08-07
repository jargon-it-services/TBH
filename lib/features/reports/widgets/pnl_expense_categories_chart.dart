import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Expense Categories" card — a donut chart plus a label/percentage
/// legend, built the same way the dashboard's own
/// `RevenueContributionChart` builds its pie-plus-legend (same
/// `PieChart`/`centerSpaceRadius` shape, same "never assume a fixed
/// slice count" data-driven rendering) — kept as its own small widget
/// here since that one lives inside the dashboard feature's private
/// widgets file.
class PnlExpenseCategoriesChart extends StatelessWidget {
  final PnlExpenseCategories categories;

  const PnlExpenseCategoriesChart({super.key, required this.categories});

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

  double get _total => categories.items.fold(0.0, (sum, s) => sum + s.value);

  @override
  Widget build(BuildContext context) {
    final slices = categories.items;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.donut_large_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(categories.title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (slices.isEmpty || _total == 0)
            const AnimatedEmptyState(
              icon: Icons.donut_large_outlined,
              title: 'No Expense Split Available',
              message:
                  'A category-wise breakdown will appear once expenses are recorded for this period.',
              height: 180,
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: 150,
                  width: 150,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 42,
                      sectionsSpace: 2,
                      sections: List.generate(slices.length, (index) {
                        final slice = slices[index];
                        return PieChartSectionData(
                          value: slice.value,
                          color: _sliceColors[index % _sliceColors.length],
                          radius: 42,
                          showTitle: false,
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.horizontalMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(slices.length, (index) {
                      final slice = slices[index];
                      final percent = _total == 0
                          ? 0.0
                          : (slice.value / _total) * 100;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
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
                                slice.label,
                                style: AppTextStyles.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "${percent.toStringAsFixed(0)}%",
                              style: AppTextStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
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
}
