import '../../core/services/DataModels/subscription_models.dart';

/// One resolved call-to-action for a plan card: what the button says,
/// and whether it's tappable at all.
class SubscriptionCta {
  final String label;
  final bool enabled;

  const SubscriptionCta(this.label, this.enabled);

  @override
  bool operator ==(Object other) =>
      other is SubscriptionCta && other.label == label && other.enabled == enabled;

  @override
  int get hashCode => Object.hash(label, enabled);

  @override
  String toString() => 'SubscriptionCta($label, enabled: $enabled)';
}

/// Resolves the CTA label/enabled-state for one [candidate] plan card,
/// given the org's current [status]. A single pure function with no
/// Flutter/widget dependency, kept deliberately "trivial to delete
/// later" (per the API contract) once the backend starts returning
/// `button: { label, enabled }` per plan itself -- at that point every
/// call site here becomes a one-line read of the response instead.
///
/// Implements the resolution table from subscription-api-responses.md
/// exactly, in priority order (first matching rule wins):
///
///  1. `ui.locked == "support"`                          -> Locked
///  2. candidate is the current active plan                -> Current Plan
///  3. candidate is Trial, org already had a plan            -> Not Available
///  4. candidate is Trial, no org exists yet                 -> Start Free Trial
///  5. `ui.locked == "renew"`, candidate rank == lastPlan     -> {renewVerb}
///  6. `ui.locked == "renew"`, candidate rank >  lastPlan     -> {renewVerb} & Upgrade
///  7. `ui.locked == "renew"`, candidate rank <  lastPlan     -> {renewVerb} & Downgrade
///  8. no organization yet                                   -> Subscribe
///  9. candidate rank > current rank                         -> Upgrade
/// 10. candidate rank < current rank                         -> Downgrade
class SubscriptionCtaResolver {
  const SubscriptionCtaResolver._();

  static SubscriptionCta resolve({
    required PlanCatalogItem candidate,
    required SubscriptionStatusResponse status,
  }) {
    final organization = status.organization;
    final ui = status.ui;

    // 1. Suspended -- every card is locked, regardless of rank.
    if (ui.locked == 'support') {
      return const SubscriptionCta('Locked', false);
    }

    // 2. This candidate IS the org's current, active plan.
    if (organization != null &&
        organization.status == TenantStatus.active &&
        candidate.planId == organization.plan) {
      return const SubscriptionCta('Current Plan', false);
    }

    // 3 & 4. Trial candidate.
    if (candidate.planId == TenantPlan.trial) {
      return organization == null
          ? const SubscriptionCta('Start Free Trial', true)
          : const SubscriptionCta('Not Available', false);
    }

    // 5, 6, 7. Read-only (expired/cancelled) -- self-serve renew allowed,
    // compared against the org's *last* plan, not its current one.
    if (ui.locked == 'renew') {
      final renewVerb = ui.renewVerb ?? 'Renew';
      final lastPlanRank = ui.lastPlan?.planId.rank;

      if (lastPlanRank != null) {
        if (candidate.planId.rank == lastPlanRank) {
          return SubscriptionCta(renewVerb, true);
        }
        if (candidate.planId.rank > lastPlanRank) {
          return SubscriptionCta('$renewVerb & Upgrade', true);
        }
        return SubscriptionCta('$renewVerb & Downgrade', true);
      }
      // No lastPlan on record (shouldn't happen alongside locked ==
      // "renew" per the contract) -- fail safe to the plain renew verb
      // rather than crash on a null rank comparison.
      return SubscriptionCta(renewVerb, true);
    }

    // 8. No org yet, non-trial candidate.
    if (organization == null) {
      return const SubscriptionCta('Subscribe', true);
    }

    // 9 & 10. Healthy active org -- compare against its current plan.
    if (candidate.planId.rank > organization.plan.rank) {
      return const SubscriptionCta('Upgrade', true);
    }
    if (candidate.planId.rank < organization.plan.rank) {
      return const SubscriptionCta('Downgrade', true);
    }

    // Same rank but not caught by rule 2 above (e.g. org status isn't
    // exactly `active` yet somehow) -- safest fallback is a disabled
    // "Current Plan" rather than presenting a misleading enabled CTA.
    return const SubscriptionCta('Current Plan', false);
  }
}
