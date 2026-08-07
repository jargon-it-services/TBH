import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payment_mode_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Total Received" card — the headline figure plus a signed
/// percentage delta against the comparison period the API names
/// (`comparison_label`, e.g. "vs last month").
class PaymentModeTotalCard extends StatelessWidget {
  final PaymentModeSummary summary;
  final String currencySymbol;

  const PaymentModeTotalCard({
    super.key,
    required this.summary,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = summary.changePercent >= 0;
    final deltaColor = isPositive ? AppColors.success : AppColors.error;

    return CardWrapper(
      child: Column(
        children: [
          Text('Total Received', style: AppTextStyles.bodySmall),
          const SizedBox(height: 6),
          Text(
            CurrencyUtils.format(summary.totalReceived, symbol: currencySymbol),
            style: AppTextStyles.h1,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: deltaColor,
              ),
              const SizedBox(width: 2),
              Text(
                "${summary.changePercent.abs().toStringAsFixed(1)}% ${summary.comparisonLabel}",
                style: AppTextStyles.caption.copyWith(
                  color: deltaColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
