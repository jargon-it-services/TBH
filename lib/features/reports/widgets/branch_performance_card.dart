import 'package:flutter/material.dart';

import '../../../core/services/DataModels/branch_performance_report_model.dart';
import '../../../core/services/currency_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/animated_empty_state.dart';
import '../../../core/widgets/card_wrapper.dart';

/// "Branch Performance" card — one block per branch with three
/// proportional bars (Revenue / Expenses / Profit), each scaled
/// against the highest value of its own kind across all branches so
/// the comparison stays meaningful branch-to-branch. Built the same
/// way `PaymentModeBars` renders however many `modes[]` the API sends
/// — however many `items[]` come back, that many blocks render, never
/// a hardcoded branch count.
class BranchPerformanceCard extends StatelessWidget {
  final BranchPerformanceSection section;
  final String currencySymbol;

  const BranchPerformanceCard({
    super.key,
    required this.section,
    required this.currencySymbol,
  });

  static const Color _revenueColor = AppColors.primary;
  static const Color _expenseColor = AppColors.secondary;
  static const Color _profitColor = AppColors.success;

  @override
  Widget build(BuildContext context) {
    final items = section.items;

    return CardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_outlined, color: AppColors.primary),
              const SizedBox(width: AppSpacing.horizontalSmall),
              Expanded(child: Text(section.title, style: AppTextStyles.h3)),
              const _LegendDot(color: _revenueColor, label: 'Revenue'),
              const SizedBox(width: 10),
              const _LegendDot(color: _expenseColor, label: 'Expenses'),
              const SizedBox(width: 10),
              const _LegendDot(color: _profitColor, label: 'Profit'),
            ],
          ),
          const SizedBox(height: AppSpacing.verticalMedium),
          if (items.isEmpty)
            const AnimatedEmptyState(
              icon: Icons.storefront_outlined,
              title: 'No Branch Data Yet',
              message:
                  'A revenue, expense and profit breakdown per branch will appear once data is available.',
              height: 180,
            )
          else
            _buildBranchRows(items),
        ],
      ),
    );
  }

  Widget _buildBranchRows(List<BranchPerformanceItem> items) {
    final maxRevenue = items.map((e) => e.revenue).fold<double>(0, (a, b) => a > b ? a : b);
    final maxExpenses = items.map((e) => e.expenses).fold<double>(0, (a, b) => a > b ? a : b);
    final maxProfit = items.map((e) => e.profit).fold<double>(0, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          _BranchBlock(
            item: items[i],
            currencySymbol: currencySymbol,
            maxRevenue: maxRevenue,
            maxExpenses: maxExpenses,
            maxProfit: maxProfit,
            revenueColor: _revenueColor,
            expenseColor: _expenseColor,
            profitColor: _profitColor,
          ),
          if (i != items.length - 1) ...[
            const SizedBox(height: AppSpacing.verticalMedium),
            Divider(color: AppColors.divider, height: 1),
            const SizedBox(height: AppSpacing.verticalMedium),
          ],
        ],
      ],
    );
  }
}

class _BranchBlock extends StatelessWidget {
  final BranchPerformanceItem item;
  final String currencySymbol;
  final double maxRevenue;
  final double maxExpenses;
  final double maxProfit;
  final Color revenueColor;
  final Color expenseColor;
  final Color profitColor;

  const _BranchBlock({
    required this.item,
    required this.currencySymbol,
    required this.maxRevenue,
    required this.maxExpenses,
    required this.maxProfit,
    required this.revenueColor,
    required this.expenseColor,
    required this.profitColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.name,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        _MetricBar(
          label: 'Revenue',
          value: item.revenue,
          maxValue: maxRevenue,
          color: revenueColor,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 6),
        _MetricBar(
          label: 'Expenses',
          value: item.expenses,
          maxValue: maxExpenses,
          color: expenseColor,
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 6),
        _MetricBar(
          label: 'Profit',
          value: item.profit,
          maxValue: maxProfit,
          color: profitColor,
          currencySymbol: currencySymbol,
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final double value;
  final double maxValue;
  final Color color;
  final String currencySymbol;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(label, style: AppTextStyles.caption),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.circle),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 7,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              semanticsLabel: '$label share',
              semanticsValue: CurrencyUtils.format(value, symbol: currencySymbol),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 64,
          child: Text(
            CurrencyUtils.format(value, symbol: currencySymbol),
            textAlign: TextAlign.end,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              fontSize: 12.5,
            ),
          ),
        ),
      ],
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
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption.copyWith(fontSize: 10)),
      ],
    );
  }
}
