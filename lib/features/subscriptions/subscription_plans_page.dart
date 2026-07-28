import 'package:flutter/material.dart';

import '../../core/network/apis/razorpay_api_service.dart';
import '../../core/network/apis/subscription_api.dart';
import '../../core/services/DataModels/razorpay_payment_payload_model.dart';
import '../../core/services/DataModels/subscription_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/network_state_view.dart';
import 'razorpay_service.dart';
import 'subscription_controller.dart';
import 'subscription_cta_resolver.dart';
import 'widgets/billing_cycle_toggle.dart';
import 'widgets/current_plan_card.dart';
import 'widgets/plan_card.dart';
import 'widgets/plan_comparison_table.dart';
import 'widgets/purchase_summary_sheet.dart';
import 'widgets/sticky_selection_bar.dart';
import 'widgets/subscription_banner.dart';
import 'widgets/subscription_shimmer.dart';

/// The Subscription Management screen -- backend-driven plan tiers,
/// current subscription state, and lifecycle actions (subscribe,
/// upgrade, downgrade, renew, reactivate), covering all 7 states from
/// subscription-api-responses.md.
///
/// Kept as the same public widget (name + no required constructor args)
/// as the simple 3-tier picker it replaces, since `DashboardAlertCard`
/// already navigates here via `const SubscriptionPlansPage()` for the
/// "subscription" alert action -- that call site needed no changes.
class SubscriptionPlansPage extends StatefulWidget {
  /// Which lifecycle fixture to load in mock mode -- has no effect
  /// once the app talks to a real backend. Defaults to Trial, the
  /// most common "why am I here" entry point.
  final SubscriptionMockScenario mockScenario;

  const SubscriptionPlansPage({
    super.key,
    this.mockScenario = SubscriptionMockScenario.trial,
  });

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  late final SubscriptionScreenController _controller;
  final RazorpayService _razorpayService = RazorpayService();
  final RazorpayApiService _razorpayApi = RazorpayApiService();
  final SubscriptionApi _subscriptionApi = SubscriptionApi();

  /// `Scaffold.bottomNavigationBar` is persistent chrome that paints
  /// *above* a `showModalBottomSheet` route, not behind it -- left
  /// alone, [StickySelectionBar] stays visible and overlapping the
  /// purchase sheet the moment it opens (this is what produced the
  /// blank/gray-looking sheet: the sheet was rendering correctly, just
  /// squeezed behind the still-visible sticky bar). Tracked here so
  /// [_bottomBar] can hide it for the sheet's lifetime.
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = SubscriptionScreenController(
      mockScenario: widget.mockScenario,
    );
    _controller.addListener(_onControllerChanged);
    _razorpayService.init();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _razorpayService.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Same Razorpay status resolution as before this rewrite --
  /// unchanged.
  String _resolvePaymentStatus(RazorpayPaymentResult result) {
    if (result.success) return 'SUCCESS';
    if (result.errorCode == 2) return 'CANCELLED'; // user-cancelled
    return 'FAILED';
  }

  void _openPurchaseSheet(PlanCatalogItem plan, SubscriptionCta cta) {
    _controller.selectPlan(plan.planId);

    setState(() => _isSheetOpen = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => PurchaseSummarySheet(
        plan: plan,
        billingCycle: _controller.billingCycle,
        ctaLabel: cta.label,
        onConfirm: () => _handlePurchase(plan, sheetContext),
      ),
    ).whenComplete(() {
      // Runs whether the sheet closed via a successful purchase
      // (Navigator.pop in _handlePurchase), swipe-to-dismiss, or a tap
      // outside it -- the sticky bar should reappear (if a plan is
      // still selected) in every one of those cases.
      if (mounted) setState(() => _isSheetOpen = false);
    });
  }

  Future<void> _handlePurchase(
    PlanCatalogItem plan,
    BuildContext sheetContext,
  ) async {
    if (plan.isFree) {
      await _handleFreeTrialActivation(sheetContext);
      return;
    }
    await _handlePaidPurchase(plan, sheetContext);
  }

  /// Free plans skip payment entirely and call activation directly
  /// (contract §9).
  Future<void> _handleFreeTrialActivation(BuildContext sheetContext) async {
    _controller.startPurchase();

    final result = await _subscriptionApi.activateFreeTrial(
      orgId: _controller.orgId,
    );

    _controller.finishPurchase();
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(sheetContext).pop();
      _controller.clearSelection();
      await _controller.refreshStatus();
      if (!mounted) return;
      AppSnackbar.success(context, 'Free trial started 🎉');
    } else {
      AppSnackbar.error(context, result.error ?? 'Unable to start your trial');
    }
  }

  /// Same 4-step order -> checkout -> save-result -> feedback flow the
  /// previous `SubscriptionPlansPage` used, reusing
  /// `RazorpayApiService`/`RazorpayService` completely unchanged --
  /// only the plan/amount source (the new catalog + billing cycle,
  /// instead of the old hardcoded 3-tier list) is different.
  Future<void> _handlePaidPurchase(
    PlanCatalogItem plan,
    BuildContext sheetContext,
  ) async {
    _controller.startPurchase();

    final isAnnual = _controller.billingCycle == BillingCycle.annual;
    final amount = isAnnual
        ? (plan.billing.annual?.price ?? 0)
        : (plan.billing.monthly?.price ?? 0);

    final orderResponse = await _razorpayApi.createOrder(
      amountInPaise: amount * 100,
      currency: 'INR',
      planId: plan.planId.apiValue,
    );

    if (!orderResponse.isSuccess || orderResponse.data == null) {
      _controller.finishPurchase();
      if (!mounted) return;
      AppSnackbar.error(
        context,
        orderResponse.error ?? 'Unable to create order',
      );
      return;
    }

    final order = orderResponse.data!;

    final result = await _razorpayService.startPayment(
      amountInRupees: amount,
      planName: plan.name,
      orderId: order.orderId,
    );

    if (!mounted) return;

    final status = _resolvePaymentStatus(result);

    await _razorpayApi.savePaymentResult(
      payload: RazorpayPaymentPayload(
        orderId: order.orderId,
        status: status,
        amount: amount * 100,
        planId: plan.planId.apiValue,
        platform: 'flutter',
        createdAt: DateTime.now(),
        paymentId: result.paymentId,
        signature: result.signature,
        errorCode: result.errorCode,
        errorReason: result.errorMessage,
      ),
    );

    _controller.finishPurchase();
    if (!mounted) return;

    if (result.success) {
      Navigator.of(sheetContext).pop();
      _controller.clearSelection();
      await _controller.refreshStatus();
      if (!mounted) return;
      AppSnackbar.success(context, 'Subscription activated 🎉');
    } else {
      AppSnackbar.error(context, 'Payment failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(
          'Subscription',
          style: AppTextStyles.h2.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      // bottomNavigationBar: _bottomBar(),
      body: SafeArea(child: _body()),
    );
  }

  // Widget? _bottomBar() {
  //   final selectedPlan = _controller.selectedPlan;
  //   if (_controller.phase != SubscriptionLoadPhase.loaded ||
  //       selectedPlan == null ||
  //       _isSheetOpen) {
  //     return null;
  //   }
  //   final cta = _controller.ctaFor(selectedPlan);
  //   return StickySelectionBar(
  //     plan: selectedPlan,
  //     billingCycle: _controller.billingCycle,
  //     ctaLabel: cta.label,
  //     onContinue: () => _openPurchaseSheet(selectedPlan, cta),
  //     onDismiss: _controller.clearSelection,
  //   );
  // }

  Widget _body() {
    switch (_controller.phase) {
      case SubscriptionLoadPhase.loading:
        return const SubscriptionShimmer();

      case SubscriptionLoadPhase.error:
        return NetworkStateView(
          isOffline: _controller.isOffline,
          message: _controller.errorMessage,
          onRetry: _controller.load,
        );

      case SubscriptionLoadPhase.loaded:
        final catalog = _controller.catalog;
        if (catalog == null || catalog.plans.isEmpty) {
          return const AnimatedEmptyState(
            icon: Icons.workspace_premium_outlined,
            title: 'Nothing to show yet',
            message: 'No subscription plans available.',
          );
        }
        return _loadedContent(catalog.plans, _controller.status!);
    }
  }

  Widget _loadedContent(
    List<PlanCatalogItem> plans,
    SubscriptionStatusResponse status,
  ) {
    final ui = status.ui;
    final organization = status.organization;
    final isSuspended = ui.locked == 'support';
    final showCurrentPlanCard = organization != null && ui.lastPlan == null;

    // At least one paid plan's annual discount, for the toggle's badge
    // — read off the catalog rather than hardcoded, so it stays correct
    // if the discount ever differs per plan.
    final annualDiscount = plans
        .map((p) => p.billing.annual?.discountPercentage)
        .firstWhere((d) => d != null, orElse: () => null);

    return IgnorePointer(
      ignoring: _controller.isPurchasing,
      child: Opacity(
        opacity: _controller.isPurchasing ? 0.6 : 1,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.page),
          children: [
            if (ui.showBanner && ui.banner != null) ...[
              SubscriptionBanner(banner: ui.banner!),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            if (showCurrentPlanCard) ...[
              CurrentPlanCard(
                organization: organization!,
                remainingDays: ui.remainingDays,
                totalDays: ui.totalDays,
              ),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            BillingCycleToggle(
              value: _controller.billingCycle,
              onChanged: _controller.setBillingCycle,
              annualDiscountPercentage: annualDiscount,
            ),
            const SizedBox(height: AppSpacing.verticalMedium),
            for (final plan in plans) ...[
              _planCardFor(plan, isSuspended),
              const SizedBox(height: AppSpacing.verticalMedium),
            ],
            Text(
              'Compare plans',
              style: AppTextStyles.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.verticalSmall),
            isSuspended
                ? const PlanComparisonLockedNotice()
                : PlanComparisonTable(plans: plans),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _planCardFor(PlanCatalogItem plan, bool isSuspended) {
    final cta = _controller.ctaFor(plan);
    final isCurrentPlan = cta.label == 'Current Plan';
    final isSelected = _controller.selectedPlanId == plan.planId;

    return PlanCard(
      plan: plan,
      billingCycle: _controller.billingCycle,
      cta: cta,
      isSelected: isSelected,
      isCurrentPlan: isCurrentPlan,
      isLocked: isSuspended,
      onSelectCard: () => _controller.selectPlan(plan.planId),
      onCtaTap: () => _openPurchaseSheet(plan, cta),
    );
  }
}
