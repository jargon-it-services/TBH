import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payment_mode_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';
import 'payment_mode_style.dart';

/// Cash / UPI / Card rows — icon, a proportional progress bar, the
/// amount, and the share of the total. However many `modes[]` the API
/// sends is however many rows render (never a hardcoded 3), so a
/// future mode the backend adds shows up automatically.
class PaymentModeBars extends StatelessWidget {
  final List<PaymentModeItem> modes;
  final String currencySymbol;

  const PaymentModeBars({
    super.key,
    required this.modes,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    if (modes.isEmpty) {
      return const CardWrapper(
        child: AnimatedEmptyState(
          icon: Icons.payments_outlined,
          title: 'No Payments Yet',
          message: 'A breakdown by payment mode will appear once payments are recorded.',
          height: 160,
        ),
      );
    }

    return CardWrapper(
      child: Column(
        children: [
          for (int i = 0; i < modes.length; i++) ...[
            _ModeRow(item: modes[i], currencySymbol: currencySymbol),
            if (i != modes.length - 1) const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final PaymentModeItem item;
  final String currencySymbol;

  const _ModeRow({required this.item, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final style = PaymentModeStyle.of(item.key);
    final fraction = (item.percent / 100).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: style.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          alignment: Alignment.center,
          child: Icon(style.icon, color: style.color, size: 19),
        ),
        const SizedBox(width: AppSpacing.horizontalMedium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.circle),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(style.color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.horizontalMedium),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyUtils.format(item.amount, symbol: currencySymbol),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "${item.percent.toStringAsFixed(1)}%",
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }
}
