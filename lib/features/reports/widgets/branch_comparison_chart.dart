import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/branch_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// One vertical-bar comparison chart, one bar per branch. Reused for
/// Revenue Comparison, Profit Comparison and Expense Comparison —
/// those three cards are the same chart against a different value
/// picked off `BranchPerformanceItem` ([valueOf]), so this widget owns
/// the chart itself and each caller just supplies its title, color and
/// value selector rather than three near-duplicate chart widgets.
class BranchComparisonChart extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<BranchPerformanceItem> items;
  final double Function(BranchPerformanceItem item) valueOf;
  final String currencySymbol;
  final double height;

  const BranchComparisonChart({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.valueOf,
    required this.currencySymbol,
    this.height = 200,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Expanded(
                child: Text(title, style: AppTextStyles.h3, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (items.isEmpty)
            AnimatedEmptyState(
              icon: icon,
              title: 'No Data Yet',
              message: 'A branch-wise comparison will appear once data is available.',
              height: height - 20,
            )
          else
            _chart(),
        ],
      ),
    );
  }

  Widget _chart() {
    final maxValue = items.map(valueOf).fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;

    return Semantics(
      label: _summary(),
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          child: BarChart(
            BarChartData(
              minY: 0,
              maxY: safeMax * 1.2,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => AppColors.textPrimary,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final branch = items[group.x.toInt()];
                    return BarTooltipItem(
                      "${branch.name}\n${CurrencyUtils.format(rod.toY, symbol: currencySymbol)}",
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _shortLabel(items[index].name),
                          style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(items.length, (i) {
                final value = valueOf(items[i]);
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: value,
                      color: color,
                      width: 22,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  /// Two-letter shorthand (e.g. "Downtown Branch" -> "DT") so labels
  /// stay readable at narrow bar widths instead of wrapping or getting
  /// clipped, matching the reference design.
  String _shortLabel(String name) {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

  String _summary() {
    final parts = items.map(
      (e) => '${e.name}: ${CurrencyUtils.format(valueOf(e), symbol: currencySymbol)}',
    );
    return '$title. ${parts.join('. ')}.';
  }
}
