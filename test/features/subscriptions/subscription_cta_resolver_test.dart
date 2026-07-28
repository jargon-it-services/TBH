import 'package:flutter_test/flutter_test.dart';
import 'package:tbh/core/services/DataModels/subscription_models.dart';
import 'package:tbh/features/subscriptions/subscription_cta_resolver.dart';

/// ---- tiny builders so each test only states what it's varying ----

PlanCatalogItem _plan(TenantPlan id, {bool free = false}) {
  return PlanCatalogItem(
    planId: id,
    name: id.displayName,
    description: '',
    isFree: free,
    recommended: false,
    badge: null,
    billing: const PlanBilling(),
    limits: const PlanLimits(maxUsers: 10, maxBranches: 1),
    features: const PlanFeatureFlags(
      fullReportsPnl: false,
      emailInvites: false,
      whiteLabelBranding: false,
      apiAccess: false,
    ),
  );
}

OrganizationSummary _org(TenantPlan plan, TenantStatus status) {
  return OrganizationSummary(
    id: 'ORG_1',
    code: 'ORG1',
    name: 'Test Org',
    plan: plan,
    status: status,
    trialExpiresAt: null,
    planExpiresAt: null,
    userCount: 1,
    branchCount: 1,
  );
}

SubscriptionUiMeta _ui({
  String? locked,
  String? renewVerb,
  TenantPlan? lastPlanId,
}) {
  return SubscriptionUiMeta(
    remainingDays: null,
    totalDays: null,
    showBanner: false,
    banner: null,
    locked: locked,
    renewVerb: renewVerb,
    lastPlan: lastPlanId != null
        ? SubscriptionLastPlan(planId: lastPlanId, expiredOn: null)
        : null,
  );
}

SubscriptionStatusResponse _status({
  OrganizationSummary? organization,
  required SubscriptionUiMeta ui,
}) {
  return SubscriptionStatusResponse(
    organization: organization,
    subscription: null,
    ui: ui,
  );
}

void main() {
  group('SubscriptionCtaResolver — first purchase (no org yet)', () {
    final status = _status(organization: null, ui: _ui());

    test('Trial -> Start Free Trial, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.trial, free: true),
        status: status,
      );
      expect(cta, const SubscriptionCta('Start Free Trial', true));
    });

    test('Starter -> Subscribe, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.starter),
        status: status,
      );
      expect(cta, const SubscriptionCta('Subscribe', true));
    });

    test('Enterprise -> Subscribe, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.enterprise),
        status: status,
      );
      expect(cta, const SubscriptionCta('Subscribe', true));
    });
  });

  group('SubscriptionCtaResolver — active, healthy (Growth, rank 2)', () {
    final status = _status(
      organization: _org(TenantPlan.growth, TenantStatus.active),
      ui: _ui(),
    );

    test('Trial -> Not Available, disabled (org already had a plan)', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.trial, free: true),
        status: status,
      );
      expect(cta, const SubscriptionCta('Not Available', false));
    });

    test('Starter (rank 1 < 2) -> Downgrade, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.starter),
        status: status,
      );
      expect(cta, const SubscriptionCta('Downgrade', true));
    });

    test('Growth (== current) -> Current Plan, disabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.growth),
        status: status,
      );
      expect(cta, const SubscriptionCta('Current Plan', false));
    });

    test('Enterprise (rank 3 > 2) -> Upgrade, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.enterprise),
        status: status,
      );
      expect(cta, const SubscriptionCta('Upgrade', true));
    });
  });

  group('SubscriptionCtaResolver — expired (read-only, renew, lastPlan=Growth)', () {
    final status = _status(
      organization: _org(TenantPlan.growth, TenantStatus.active),
      ui: _ui(
        locked: 'renew',
        renewVerb: 'Renew',
        lastPlanId: TenantPlan.growth,
      ),
    );

    test('Starter (rank 1 < 2) -> Renew & Downgrade, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.starter),
        status: status,
      );
      expect(cta, const SubscriptionCta('Renew & Downgrade', true));
    });

    test('Growth (== lastPlan) -> Renew, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.growth),
        status: status,
      );
      expect(cta, const SubscriptionCta('Renew', true));
    });

    test('Enterprise (rank 3 > 2) -> Renew & Upgrade, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.enterprise),
        status: status,
      );
      expect(cta, const SubscriptionCta('Renew & Upgrade', true));
    });

    test('Trial -> Not Available, disabled (org already had a plan)', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.trial, free: true),
        status: status,
      );
      expect(cta, const SubscriptionCta('Not Available', false));
    });
  });

  group('SubscriptionCtaResolver — cancelled (renewVerb: Reactivate, lastPlan=Starter)', () {
    final status = _status(
      organization: _org(TenantPlan.starter, TenantStatus.cancelled),
      ui: _ui(
        locked: 'renew',
        renewVerb: 'Reactivate',
        lastPlanId: TenantPlan.starter,
      ),
    );

    test('Starter (== lastPlan) -> Reactivate, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.starter),
        status: status,
      );
      expect(cta, const SubscriptionCta('Reactivate', true));
    });

    test('Growth (rank 2 > 1) -> Reactivate & Upgrade, enabled', () {
      final cta = SubscriptionCtaResolver.resolve(
        candidate: _plan(TenantPlan.growth),
        status: status,
      );
      expect(cta, const SubscriptionCta('Reactivate & Upgrade', true));
    });
  });

  group('SubscriptionCtaResolver — suspended (support-locked)', () {
    final status = _status(
      organization: _org(TenantPlan.growth, TenantStatus.suspended),
      ui: _ui(locked: 'support'),
    );

    test('Every plan (incl. current/Growth) -> Locked, disabled', () {
      for (final id in TenantPlan.values) {
        final cta = SubscriptionCtaResolver.resolve(
          candidate: _plan(id),
          status: status,
        );
        expect(cta, const SubscriptionCta('Locked', false), reason: id.name);
      }
    });
  });
}
