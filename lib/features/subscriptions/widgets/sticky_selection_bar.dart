import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_tokens.dart';

String _formatMoney(int amount, String currency) {
  final symbol = currency == 'INR' ? '₹' : currency;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 0,
  ).format(amount);
}

/// Appears once a plan card is selected (card body tap, not the CTA
/// button itself — see `PlanCard`). Shows the live price for the
/// currently selected billing cycle and a single primary "Continue ·
/// {action}" button that opens the purchase-summary bottom sheet.
class StickySelectionBar extends StatelessWidget {
  final PlanCatalogItem plan;
  final BillingCycle billingCycle;
  final String ctaLabel;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const StickySelectionBar({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.ctaLabel,
    required this.onContinue,
    required this.onDismiss,
  });

  String get _priceText {
    if (plan.isFree) return 'Free';
    if (billingCycle == BillingCycle.annual && plan.billing.annual != null) {
      return '${_formatMoney(plan.billing.annual!.price, plan.billing.annual!.currency)}/yr';
    }
    if (plan.billing.monthly != null) {
      return '${_formatMoney(plan.billing.monthly!.price, plan.billing.monthly!.currency)}/mo';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.page,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppRadius.large),
            topRight: Radius.circular(AppRadius.large),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: SubscriptionTokens.sub),
              tooltip: 'Clear selection',
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: SubscriptionTokens.sub,
                    ),
                  ),
                  Text(
                    _priceText,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.bold,
                      color: SubscriptionTokens.ink,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: SubscriptionTokens.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue · $ctaLabel',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
