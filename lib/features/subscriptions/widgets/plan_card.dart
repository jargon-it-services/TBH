import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../subscription_cta_resolver.dart';
import '../subscription_tokens.dart';
import 'subscription_feature_rows.dart';

String _formatMoney(int amount, String currency) {
  final symbol = currency == 'INR' ? '₹' : currency;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 0,
  ).format(amount);
}

/// One plan tile. Three visual states, all driven by plain booleans the
/// caller resolves (this widget makes no lifecycle-state decisions of
/// its own):
///
/// - Normal/selectable: tappable, shows a secondary-colored border +
///   checkmark badge when [isSelected].
/// - Current plan ([isCurrentPlan]): primary-colored accent border,
///   "Current Plan" ribbon, never selectable.
/// - Locked ([isLocked], Suspended only): plan name stays visible;
///   everything else is blurred via [ImageFiltered] and non-interactive,
///   with a centered lock icon + "Pricing hidden" overlay. No badge
///   ribbon, no checkmark, ever, on a locked card.
class PlanCard extends StatelessWidget {
  final PlanCatalogItem plan;
  final BillingCycle billingCycle;
  final SubscriptionCta cta;
  final bool isSelected;
  final bool isCurrentPlan;
  final bool isLocked;
  final VoidCallback? onSelectCard;
  final VoidCallback? onCtaTap;

  const PlanCard({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.cta,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.isLocked,
    this.onSelectCard,
    this.onCtaTap,
  });

  bool get _isSelectable => !isLocked && !isCurrentPlan && cta.enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? SubscriptionTokens.secondary
        : isCurrentPlan
            ? SubscriptionTokens.primary
            : SubscriptionTokens.line;
    final borderWidth = isSelected || isCurrentPlan ? 2.0 : 1.0;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: borderColor, width: borderWidth),
        boxShadow: [
          BoxShadow(
            blurRadius: (plan.recommended && !isLocked) ? 18 : 10,
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(),
                if (!isLocked) ...[
                  const SizedBox(height: 10),
                  _blurableBody(),
                ] else ...[
                  const SizedBox(height: 10),
                  _blurredPlaceholderBody(),
                ],
              ],
            ),
          ),
          if (!isLocked && plan.recommended && plan.badge != null)
            _popularRibbon(),
          if (!isLocked && isSelected) _selectedCheckmark(),
          if (isLocked) _lockedOverlay(),
        ],
      ),
    );

    if (!_isSelectable) {
      return card;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelectCard,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: card,
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            plan.name,
            style: AppTextStyles.h3.copyWith(color: SubscriptionTokens.ink),
          ),
        ),
        if (isCurrentPlan && !isLocked)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: SubscriptionTokens.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SubscriptionTokens.primary,
              ),
            ),
          ),
      ],
    );
  }

  /// The real, informative body -- price, description, feature rows.
  /// Wrapped in [ImageFiltered] with a blur when [isLocked].
  Widget _blurableBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.description,
          style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
        ),
        const SizedBox(height: 12),
        _priceBlock(),
        const SizedBox(height: 14),
        ...subscriptionFeatureRows.map(_featureRow),
        const SizedBox(height: 14),
        _ctaButton(),
      ],
    );
  }

  /// Same body, but blurred + non-interactive -- used only when
  /// [isLocked]. Kept as a genuinely separate (blurred) render of the
  /// real content, per spec, rather than a fake/greyed-out mockup.
  Widget _blurredPlaceholderBody() {
    return IgnorePointer(
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: _blurableBody(),
      ),
    );
  }

  Widget _priceBlock() {
    if (plan.isFree) {
      return Text(
        'Free',
        style: AppTextStyles.h2.copyWith(
          color: SubscriptionTokens.ink,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    final monthly = plan.billing.monthly;
    final annual = plan.billing.annual;

    if (billingCycle == BillingCycle.annual && annual != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _formatMoney(annual.price, annual.currency),
            style: AppTextStyles.h2.copyWith(
              color: SubscriptionTokens.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatMoney(annual.strikePrice, annual.currency),
            style: AppTextStyles.bodySmall.copyWith(
              color: SubscriptionTokens.sub,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: SubscriptionTokens.secondary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${annual.discountPercentage}% off',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SubscriptionTokens.secondary,
              ),
            ),
          ),
        ],
      );
    }

    if (monthly != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            _formatMoney(monthly.price, monthly.currency),
            style: AppTextStyles.h2.copyWith(
              color: SubscriptionTokens.ink,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '/mo',
            style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
          ),
        ],
      );
    }

    // No billing at all and not free -- shouldn't happen per catalog,
    // fail safe rather than throw.
    return Text('—', style: AppTextStyles.h2.copyWith(color: SubscriptionTokens.ink));
  }

  Widget _featureRow(SubscriptionFeatureRow row) {
    final value = row.valueOf(plan);
    final isLimit = row.type == SubscriptionFeatureRowType.limit;
    final boolValue = isLimit ? false : value as bool;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          isLimit
              ? Icon(row.icon, size: 16, color: SubscriptionTokens.sub)
              : Icon(
                  boolValue ? Icons.check_circle : Icons.cancel_outlined,
                  size: 16,
                  color: boolValue
                      ? SubscriptionTokens.success
                      : SubscriptionTokens.sub.withOpacity(0.5),
                ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLimit
                  ? '${row.label}: ${formatFeatureLimit(value as int?)}'
                  : row.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: (!isLimit && !boolValue)
                    ? SubscriptionTokens.sub.withOpacity(0.6)
                    : SubscriptionTokens.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ctaButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: cta.enabled ? onCtaTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              cta.enabled ? SubscriptionTokens.primary : SubscriptionTokens.line,
          foregroundColor: cta.enabled ? Colors.white : SubscriptionTokens.sub,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          elevation: 0,
        ),
        child: Text(
          cta.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _popularRibbon() {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: SubscriptionTokens.secondary,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(AppRadius.large),
            bottomLeft: Radius.circular(AppRadius.medium),
          ),
        ),
        child: Text(
          plan.badge!.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _selectedCheckmark() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          color: SubscriptionTokens.secondary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _lockedOverlay() {
    return Positioned.fill(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Icon(Icons.lock_outline, color: SubscriptionTokens.sub, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              'Pricing hidden',
              style: AppTextStyles.bodySmall.copyWith(
                color: SubscriptionTokens.sub,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
