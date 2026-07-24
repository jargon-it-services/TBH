import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';
import 'animated_empty_state.dart';

/// =========================
/// Data model for chart points
/// =========================
class RevenueTrendData {
  final String label;
  final double value;

  RevenueTrendData({required this.label, required this.value});
}

/// =========================
/// RevenueTrendChart Widget
/// =========================
class RevenueTrendChart extends StatelessWidget {
  final List<RevenueTrendData> revenueTrend;
  final bool hasPrevTrend;
  final bool hasNextTrend;
  final bool loading;
  final String? prevCursor;
  final String? nextCursor;
  final Function({String? cursor, bool isNext}) onLoadTrend;
  final String Function(String period)? periodLabel; // optional label builder

  const RevenueTrendChart({
    super.key,
    required this.revenueTrend,
    this.hasPrevTrend = false,
    this.hasNextTrend = false,
    this.loading = false,
    this.prevCursor,
    this.nextCursor,
    required this.onLoadTrend,
    this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (revenueTrend.isEmpty) {
      return const AnimatedEmptyState(
        icon: Icons.show_chart,
        title: "No Revenue Insights Yet",
        message:
            "Revenue trends will appear once transaction(s) are recorded for this period.",
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.page),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: AppColors.primary),
              SizedBox(width: AppSpacing.horizontalSmall),
              Text("Overall Revenue Insights", style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalSmall),
          Text(
            "This chart represents revenue performance over the last 6 ${periodLabel != null ? periodLabel!("period") : "periods"}.",
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          SizedBox(
            height: 180,
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
                        if (index < 0 || index >= revenueTrend.length)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            revenueTrend[index].label,
                            style: AppTextStyles.bodySmall.copyWith(
                              fontSize: 9,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (touchedSpot) => AppColors.secondary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          "₹${spot.y.toStringAsFixed(2)}",
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      revenueTrend.length,
                      (i) => FlSpot(i.toDouble(), revenueTrend[i].value),
                    ),
                    isCurved: true,
                    barWidth: 2,
                    color: AppColors.primary,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.09),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_trendButton(isPrev: true), _trendButton(isPrev: false)],
          ),
        ],
      ),
    );
  }

  Widget _trendButton({required bool isPrev}) {
    final bool enabled = isPrev ? hasPrevTrend : hasNextTrend;
    final String label = isPrev ? "Prev" : "Next";
    final IconData icon = isPrev ? Icons.chevron_left : Icons.chevron_right;
    final String? cursor = isPrev ? prevCursor : nextCursor;

    return TextButton(
      onPressed: enabled && !loading
          ? () => onLoadTrend(cursor: cursor, isNext: !isPrev)
          : null,
      child: loading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            )
          : Row(
              children: isPrev
                  ? [
                      Icon(
                        icon,
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textDisabled,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                      ),
                    ]
                  : [
                      Text(
                        label,
                        style: TextStyle(
                          color: enabled
                              ? AppColors.primary
                              : AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        icon,
                        color: enabled
                            ? AppColors.primary
                            : AppColors.textDisabled,
                      ),
                    ],
            ),
    );
  }
}
