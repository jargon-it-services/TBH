import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Revenue Trend" card — single-series line chart, built the same
/// way `PnlTrendChart` builds its two-series version (same
/// `LineChart`/`FlSpot` shape, gridlines, tooltip style), just with
/// one [LineChartBarData] instead of two.
class RevenueTrendChartCard extends StatelessWidget {
  final RevenueTrend trend;
  final String currencySymbol;

  const RevenueTrendChartCard({
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
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (points.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.show_chart,
              title: 'No Trend Data Yet',
              message: 'Revenue trend will appear once transactions are recorded for this period.',
              height: 180,
            )
          else
            Semantics(
              label: _trendSummary(points, currencySymbol),
              child: ExcludeSemantics(
                child: SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                              return LineTooltipItem(
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
                            (i) => FlSpot(i.toDouble(), points[i].value),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Text equivalent of the chart above, for screen readers — this
  /// trend has no separate text legend to fall back on the way the
  /// expense-breakdown donut does.
  String _trendSummary(List<RevenueTrendPoint> points, String currencySymbol) {
    final parts = points.map((p) => '${p.label}: $currencySymbol${p.value.toStringAsFixed(0)}');
    return 'Revenue trend. ${parts.join(', ')}.';
  }
}
