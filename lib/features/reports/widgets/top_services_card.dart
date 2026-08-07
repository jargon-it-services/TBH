import 'package:flutter/material.dart';

import '../../../core/services/DataModels/revenue_expense_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Top Services by Revenue" card — one row per service with a
/// proportional bar, however many `top_services.items[]` the API
/// sends (never a hardcoded 4). Row shape mirrors `PaymentModeBars`
/// minus the leading icon tile, since services don't carry a fixed
/// icon set the way payment modes do.
class TopServicesCard extends StatelessWidget {
  final TopServicesSection section;
  final String currencySymbol;

  const TopServicesCard({
    super.key,
    required this.section,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final items = section.items;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.leaderboard_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Text(section.title, style: AppTextStyles.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (items.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.leaderboard_outlined,
              title: 'No Services Yet',
              message: 'Your top services by revenue will appear here once bookings come in.',
              height: 160,
            )
          else
            Column(
              children: [
                for (int i = 0; i < items.length; i++) ...[
                  _ServiceRow(item: items[i], currencySymbol: currencySymbol),
                  if (i != items.length - 1)
                    const SizedBox(height: AppSpacing.verticalMedium),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final TopServiceItem item;
  final String currencySymbol;

  const _ServiceRow({required this.item, required this.currencySymbol});

  @override
  Widget build(BuildContext context) {
    final fraction = (item.percent / 100).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  semanticsLabel: '${item.label} share of total revenue',
                  semanticsValue: '${item.percent.toStringAsFixed(0)} percent',
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
              "${item.percent.toStringAsFixed(0)}%",
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ],
    );
  }
}
