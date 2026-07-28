import 'package:flutter/material.dart';

import '../../core/network/apis/subscription_api.dart';
import '../../core/services/DataModels/subscription_models.dart';
import 'subscription_cta_resolver.dart';

/// Screen-level data phase -- separate from [SubscriptionScreenController.isPurchasing],
/// which tracks the payment bottom sheet independently (a purchase can
/// be in flight while the underlying data is already `loaded`).
enum SubscriptionLoadPhase { loading, loaded, error }

/// Holds all state for the Subscription screen: the plan catalog, the
/// org's current subscription status, the Monthly/Annual toggle, and
/// which plan card (if any) is currently selected. Kept as a plain
/// [ChangeNotifier] -- same shape as the original `SubscriptionController`
/// it replaces -- rather than introducing Cubit/Bloc.
///
/// Async orchestration for the purchase itself (Razorpay + the
/// existing `RazorpayApiService`) intentionally stays in
/// `SubscriptionPlansPage`'s State, exactly where it lived before this
/// rewrite -- this controller only tracks the resulting state
/// ([isPurchasing]) via [startPurchase]/[finishPurchase].
class SubscriptionScreenController extends ChangeNotifier {
  SubscriptionScreenController({
    SubscriptionApi? api,
    this.orgId = 'CURRENT_ORG',
    this.mockScenario = SubscriptionMockScenario.trial,
  }) : _api = api ?? SubscriptionApi();

  final SubscriptionApi _api;

  /// No org-id concept exists yet anywhere else in the app (session
  /// only tracks token/userName/role) -- this is a placeholder until
  /// one does. Has no effect in mock mode.
  final String orgId;

  /// Which of the 7 contract fixtures to load in mock mode (see
  /// [SubscriptionMockScenario]). No effect once the app talks to a
  /// real backend.
  final SubscriptionMockScenario mockScenario;

  SubscriptionLoadPhase phase = SubscriptionLoadPhase.loading;
  String? errorMessage;
  bool isOffline = false;

  PlanCatalogResponse? catalog;
  SubscriptionStatusResponse? status;

  BillingCycle billingCycle = BillingCycle.monthly;
  TenantPlan? selectedPlanId;

  bool isPurchasing = false;

  /// Loads both the plan catalog and the org's subscription status
  /// concurrently (both requests are issued before either is awaited).
  Future<void> load() async {
    phase = SubscriptionLoadPhase.loading;
    errorMessage = null;
    notifyListeners();

    final catalogFuture = _api.fetchPlanCatalog();
    final statusFuture = _api.fetchSubscriptionStatus(
      orgId: orgId,
      mockScenario: mockScenario,
    );

    final catalogResponse = await catalogFuture;
    final statusResponse = await statusFuture;

    if (!catalogResponse.isSuccess || catalogResponse.data == null) {
      phase = SubscriptionLoadPhase.error;
      errorMessage = catalogResponse.error;
      isOffline = catalogResponse.isConnectivityError;
      notifyListeners();
      return;
    }

    if (!statusResponse.isSuccess || statusResponse.data == null) {
      phase = SubscriptionLoadPhase.error;
      errorMessage = statusResponse.error;
      isOffline = statusResponse.isConnectivityError;
      notifyListeners();
      return;
    }

    catalog = catalogResponse.data;
    status = statusResponse.data;
    phase = SubscriptionLoadPhase.loaded;
    notifyListeners();
  }

  /// Re-fetches subscription status only (after a purchase completes),
  /// leaving the plan catalog as-is since it never changes per-org.
  Future<void> refreshStatus() async {
    final statusResponse = await _api.fetchSubscriptionStatus(
      orgId: orgId,
      mockScenario: mockScenario,
    );
    if (statusResponse.isSuccess && statusResponse.data != null) {
      status = statusResponse.data;
      notifyListeners();
    }
  }

  void setBillingCycle(BillingCycle cycle) {
    if (billingCycle == cycle) return;
    billingCycle = cycle;
    notifyListeners();
  }

  /// Selecting a plan card. Locked/non-selectable plans should never
  /// reach this (see `PlanCard`'s own `onTap` gating), but this is
  /// re-checked here too rather than trusted blindly from the caller.
  void selectPlan(TenantPlan planId) {
    if (catalog == null || status == null) return;
    final plan = _planById(planId);
    if (plan == null) return;
    if (!ctaFor(plan).enabled) return;

    selectedPlanId = planId;
    notifyListeners();
  }

  void clearSelection() {
    if (selectedPlanId == null) return;
    selectedPlanId = null;
    notifyListeners();
  }

  void startPurchase() {
    isPurchasing = true;
    notifyListeners();
  }

  void finishPurchase() {
    isPurchasing = false;
    notifyListeners();
  }

  PlanCatalogItem? _planById(TenantPlan planId) {
    final plans = catalog?.plans;
    if (plans == null) return null;
    for (final p in plans) {
      if (p.planId == planId) return p;
    }
    return null;
  }

  PlanCatalogItem? get selectedPlan =>
      selectedPlanId != null ? _planById(selectedPlanId!) : null;

  /// Resolves the CTA for [plan] against the currently loaded [status].
  /// Returns a disabled, empty CTA if data isn't loaded yet -- callers
  /// should never be able to reach this before [phase] is `loaded`
  /// anyway, but this fails safe (a non-tappable card) rather than
  /// throwing if they somehow do.
  SubscriptionCta ctaFor(PlanCatalogItem plan) {
    final currentStatus = status;
    if (currentStatus == null) {
      return const SubscriptionCta('', false);
    }
    return SubscriptionCtaResolver.resolve(
      candidate: plan,
      status: currentStatus,
    );
  }
}
