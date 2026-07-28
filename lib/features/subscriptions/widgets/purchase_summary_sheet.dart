import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/services/DataModels/subscription_models.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/widgets/slide_action_button.dart';
import '../subscription_tokens.dart';

String _formatMoney(int amount, String currency) {
  final symbol = currency == 'INR' ? '₹' : currency;
  return NumberFormat.currency(
    locale: 'en_IN',
    symbol: symbol,
    decimalDigits: 0,
  ).format(amount);
}

/// Bottom sheet opened either from the sticky selection bar's
/// "Continue" button, or directly from a plan card's own CTA button.
///
/// Two modes, per contract §9:
/// - Paid plan: full price breakdown (plan price, annual discount, GST)
///   + payable total, then the existing [SlideActionButton] "slide to
///   pay" gesture -- the same widget/pattern the previous
///   `SubscriptionPlansPage` already used, reused unchanged here.
/// - `plan.isFree` (Trial): skips the breakdown and payment entirely --
///   a plain confirm button that calls straight through to
///   [onConfirm], which the page wires to `activateFreeTrial` rather
///   than Razorpay.
///
/// This widget only renders the breakdown and drives [onConfirm] --
/// the actual order-creation/Razorpay/save-result orchestration (and
/// any success/failure navigation) lives in `SubscriptionPlansPage`,
/// exactly where that orchestration lived before this rewrite.
class PurchaseSummarySheet extends StatefulWidget {
  final PlanCatalogItem plan;
  final BillingCycle billingCycle;
  final String ctaLabel;
  final Future<void> Function() onConfirm;

  const PurchaseSummarySheet({
    super.key,
    required this.plan,
    required this.billingCycle,
    required this.ctaLabel,
    required this.onConfirm,
  });

  @override
  State<PurchaseSummarySheet> createState() => _PurchaseSummarySheetState();
}

class _PurchaseSummarySheetState extends State<PurchaseSummarySheet> {
  bool _submitting = false;

  /// GST isn't specified anywhere in the API contract or SRS -- 18% is
  /// assumed here (the standard Indian GST rate for SaaS
  /// subscriptions) purely so the breakdown has a complete, sensible
  /// shape. Flag to product/business before shipping, same as the
  /// annual-discount and trial-length assumptions the contract itself
  /// already calls out.
  static const double _assumedGstRate = 0.18;

  int get _basePrice {
    final plan = widget.plan;
    if (plan.isFree) return 0;
    if (widget.billingCycle == BillingCycle.annual && plan.billing.annual != null) {
      return plan.billing.annual!.price;
    }
    return plan.billing.monthly?.price ?? 0;
  }

  String get _currency {
    final plan = widget.plan;
    if (widget.billingCycle == BillingCycle.annual && plan.billing.annual != null) {
      return plan.billing.annual!.currency;
    }
    return plan.billing.monthly?.currency ?? 'INR';
  }

  int get _gstAmount => (_basePrice * _assumedGstRate).round();
  int get _payableTotal => _basePrice + _gstAmount;

  Future<void> _handleConfirm() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await widget.onConfirm();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          12,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: SubscriptionTokens.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${plan.name} Plan',
                      style: AppTextStyles.h3.copyWith(color: SubscriptionTokens.ink),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: SubscriptionTokens.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.ctaLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: SubscriptionTokens.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                plan.isFree
                    ? '14-day free trial · no payment required'
                    : widget.billingCycle == BillingCycle.annual
                        ? 'Billed annually'
                        : 'Billed monthly',
                style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
              ),
              const SizedBox(height: 20),
              if (!plan.isFree) ...[
                _row('Plan price', _formatMoney(_basePrice, _currency)),
                if (widget.billingCycle == BillingCycle.annual &&
                    plan.billing.annual != null)
                  _row(
                    'Annual discount (${plan.billing.annual!.discountPercentage}%)',
                    '-${_formatMoney(plan.billing.annual!.strikePrice - plan.billing.annual!.price, _currency)}',
                    valueColor: SubscriptionTokens.success,
                  ),
                _row('GST (18%)', _formatMoney(_gstAmount, _currency)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: SubscriptionTokens.line),
                ),
                _row(
                  'Payable now',
                  _formatMoney(_payableTotal, _currency),
                  bold: true,
                ),
                const SizedBox(height: 22),
                SlideActionButton(
                  label: 'Slide to pay ${_formatMoney(_payableTotal, _currency)}',
                  submitting: _submitting,
                  onSlide: (_) => _handleConfirm(),
                ),
              ] else ...[
                Text(
                  'Start your free trial today. You can choose a paid plan '
                  'anytime before it ends — no card required now.',
                  style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SubscriptionTokens.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Start Free Trial',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: SubscriptionTokens.sub),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? SubscriptionTokens.ink,
            ),
          ),
        ],
      ),
    );
  }
}
