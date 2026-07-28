import 'package:flutter/material.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_tokens.dart';

/// Two-way Monthly/Annual toggle only -- no other billing cycles exist
/// per the plan catalog (`billing.monthly` / `billing.annual`), and
/// `trial` is never a user-selectable cycle here (Trial has no billing
/// at all -- see `PlanBilling`).
class BillingCycleToggle extends StatelessWidget {
  final BillingCycle value;
  final ValueChanged<BillingCycle> onChanged;

  /// Shown as a small badge on the Annual segment when at least one
  /// paid plan has an annual discount (they all currently do, at 17%).
  final int? annualDiscountPercentage;

  const BillingCycleToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.annualDiscountPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: SubscriptionTokens.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: SubscriptionTokens.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _segment(
              label: 'Monthly',
              selected: value == BillingCycle.monthly,
              onTap: () => onChanged(BillingCycle.monthly),
            ),
          ),
          Expanded(
            child: _segment(
              label: 'Annual',
              selected: value == BillingCycle.annual,
              onTap: () => onChanged(BillingCycle.annual),
              badge: annualDiscountPercentage != null
                  ? 'Save $annualDiscountPercentage%'
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? SubscriptionTokens.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : SubscriptionTokens.ink,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.2)
                      : SubscriptionTokens.secondary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : SubscriptionTokens.secondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
