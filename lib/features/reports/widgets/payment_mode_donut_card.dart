import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payment_mode_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';
import 'payment_mode_style.dart';

/// "Payment Mode Distribution" card — a donut chart with the total
/// amount centered in the hole, one slice per `modes[]` entry, colored
/// via the same [PaymentModeStyle] mapping the bar list uses.
class PaymentModeDonutCard extends StatelessWidget {
  final List<PaymentModeItem> modes;
  final double total;
  final String currencySymbol;

  const PaymentModeDonutCard({
    super.key,
    required this.modes,
    required this.total,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Mode Distribution', style: AppTextStyles.h3),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (modes.isEmpty || total == 0)
            const AnimatedEmptyState(
              icon: Icons.donut_large_outlined,
              title: 'No Distribution Yet',
              message: 'The payment mode split will appear once payments are recorded.',
              height: 180,
            )
          else
            Center(
              child: SizedBox(
                height: 190,
                width: 190,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Semantics(
                      label: _donutSummary(modes),
                      child: ExcludeSemantics(
                        child: PieChart(
                          PieChartData(
                            centerSpaceRadius: 56,
                            sectionsSpace: 2,
                            sections: [
                              for (final mode in modes)
                                PieChartSectionData(
                                  value: mode.percent,
                                  color: PaymentModeStyle.of(mode.key).color,
                                  radius: 38,
                                  showTitle: false,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrencyUtils.format(total, symbol: currencySymbol),
                          textAlign: TextAlign.center,
                          style: AppTextStyles.h3.copyWith(fontSize: 15),
                        ),
                        Text('Total', style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Text equivalent of the donut chart, for screen readers. Unlike
  /// the other two donuts in this feature, this card has no adjacent
  /// per-slice legend of its own (that detail lives in
  /// `PaymentModeBars` further down the page instead), so this
  /// summary is this chart's only text equivalent.
  String _donutSummary(List<PaymentModeItem> modes) {
    if (modes.isEmpty) return 'Payment mode distribution chart, no data.';
    final parts = modes.map((m) => '${m.label} ${m.percent.toStringAsFixed(0)} percent');
    return 'Payment mode distribution: ${parts.join(', ')}.';
  }
}
