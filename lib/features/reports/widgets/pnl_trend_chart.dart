import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/pnl_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "P&L Trend" card — Revenue vs Expense over the selected period, as
/// two overlaid lines. Built the same way `RevenueTrendChart` (in
/// `core/widgets`) builds its single-series line chart — same
/// `LineChart`/`FlSpot` shape, gridlines, and tooltip style — just
/// extended to two `LineChartBarData` series instead of one, since
/// that existing widget is single-series by design and used
/// specifically by the dashboard's revenue trend.
class PnlTrendChart extends StatelessWidget {
  final PnlTrend trend;
  final String currencySymbol;

  const PnlTrendChart({
    super.key,
    required this.trend,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final points = trend.points;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart_rounded, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(trend.title, style: AppTextStyles.h3),
              const Spacer(),
              _LegendDot(color: AppColors.primary, label: 'Revenue'),
              const SizedBox(width: 12),
              _LegendDot(color: AppColors.secondary, label: 'Expense'),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (points.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.show_chart,
              title: 'No Trend Data Yet',
              message:
                  'Revenue and expense trends will appear once transactions are recorded for this period.',
              height: 180,
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= points.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              points[index].label,
                              style: AppTextStyles.bodySmall.copyWith(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (touchedSpot) => AppColors.textPrimary,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final isRevenue = spot.barIndex == 0;
                          return LineTooltipItem(
                            "${isRevenue ? 'Revenue' : 'Expense'}\n"
                            "$currencySymbol${spot.y.toStringAsFixed(0)}",
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        points.length,
                        (i) => FlSpot(i.toDouble(), points[i].revenue),
                      ),
                      isCurved: true,
                      barWidth: 2.5,
                      color: AppColors.primary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.08),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        points.length,
                        (i) => FlSpot(i.toDouble(), points[i].expense),
                      ),
                      isCurved: true,
                      barWidth: 2.5,
                      color: AppColors.secondary,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
