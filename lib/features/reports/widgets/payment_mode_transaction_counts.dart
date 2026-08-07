import 'package:flutter/material.dart';

import '../../../core/services/DataModels/payment_mode_report_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import 'payment_mode_style.dart';

/// "Transactions Count" — one stat tile per payment mode, e.g. "Cash /
/// 125". Row wraps to a new line if more modes are ever added than
/// comfortably fit, rather than overflowing horizontally.
class PaymentModeTransactionCounts extends StatelessWidget {
  final List<PaymentModeItem> modes;

  const PaymentModeTransactionCounts({super.key, required this.modes});

  @override
  Widget build(BuildContext context) {
    if (modes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Transactions Count', style: AppTextStyles.h3),
        const SizedBox(height: AppSpacing.verticalMedium),
        Row(
          children: [
            for (int i = 0; i < modes.length; i++) ...[
              Expanded(child: _CountTile(item: modes[i])),
              if (i != modes.length - 1) const SizedBox(width: AppSpacing.horizontalSmall),
            ],
          ],
        ),
      ],
    );
  }
}

class _CountTile extends StatelessWidget {
  final PaymentModeItem item;

  const _CountTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final style = PaymentModeStyle.of(item.key);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            item.label,
            style: AppTextStyles.caption.copyWith(color: style.color, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.transactionCount}',
            style: AppTextStyles.h3,
          ),
        ],
      ),
    );
  }
}
