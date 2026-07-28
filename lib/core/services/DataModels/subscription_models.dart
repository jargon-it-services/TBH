// subscription_models.dart
//
// Models for the two Subscription Management endpoints:
//   GET /plans                                  -> PlanCatalogResponse
//   GET /organizations/{orgId}/subscription      -> SubscriptionStatusResponse
//
// Deliberately keeps two pairs of enums separate even though they share
// vocabulary, per the API contract's explicit modeling note:
//   - TenantPlan   (trial|starter|growth|enterprise) = OrganizationEntity.plan,
//     the PLAN TIER. Also doubles as the plan catalog's `planId`.
//   - BillingCycle (trial|monthly|annual)             = SubscriptionEntity.plan,
//     the BILLING CYCLE.
//   - TenantStatus (active|trial|suspended|cancelled) = OrganizationEntity.status.
//   - SubscriptionRecordStatus (active|expired|readOnly) = SubscriptionEntity.status.
// Collapsing any of these into one field would lose information the CTA
// resolver and UI both depend on -- see subscription_cta_resolver.dart.
//
// There is intentionally no `autoRenew` field anywhere below -- renewal
// is always a manual Org Admin action per the contract, so nothing here
// should grow one.

/// The plan tier. [rank] drives every upgrade/downgrade/CTA comparison
/// in `SubscriptionCtaResolver` -- never compare tiers by name/index
/// order of the enum declaration itself, always via [rank].
enum TenantPlan {
  trial,
  starter,
  growth,
  enterprise;

  static TenantPlan fromApiValue(String? value) {
    switch (value) {
      case 'starter':
        return TenantPlan.starter;
      case 'growth':
        return TenantPlan.growth;
      case 'enterprise':
        return TenantPlan.enterprise;
      case 'trial':
      default:
        return TenantPlan.trial;
    }
  }

  String get apiValue => name;

  /// trial=0, starter=1, growth=2, enterprise=3 -- exactly the ranking
  /// the API contract's CTA table is defined against.
  int get rank {
    switch (this) {
      case TenantPlan.trial:
        return 0;
      case TenantPlan.starter:
        return 1;
      case TenantPlan.growth:
        return 2;
      case TenantPlan.enterprise:
        return 3;
    }
  }

  String get displayName {
    switch (this) {
      case TenantPlan.trial:
        return 'Trial';
      case TenantPlan.starter:
        return 'Starter';
      case TenantPlan.growth:
        return 'Growth';
      case TenantPlan.enterprise:
        return 'Enterprise';
    }
  }
}

/// [OrganizationSummary.status] -- the tenant/org's lifecycle state.
enum TenantStatus {
  active,
  trial,
  suspended,
  cancelled;

  static TenantStatus fromApiValue(String? value) {
    switch (value) {
      case 'active':
        return TenantStatus.active;
      case 'suspended':
        return TenantStatus.suspended;
      case 'cancelled':
        return TenantStatus.cancelled;
      case 'trial':
      default:
        return TenantStatus.trial;
    }
  }
}

/// [SubscriptionRecord.plan] -- the billing cycle, separate from the
/// plan tier ([TenantPlan]) on purpose (see file header).
enum BillingCycle {
  trial,
  monthly,
  annual;

  static BillingCycle fromApiValue(String? value) {
    switch (value) {
      case 'monthly':
        return BillingCycle.monthly;
      case 'annual':
        return BillingCycle.annual;
      case 'trial':
      default:
        return BillingCycle.trial;
    }
  }
}

/// [SubscriptionRecord.status] -- separate from [TenantStatus] on
/// purpose (see file header).
enum SubscriptionRecordStatus {
  active,
  expired,
  readOnly;

  static SubscriptionRecordStatus fromApiValue(String? value) {
    switch (value) {
      case 'expired':
        return SubscriptionRecordStatus.expired;
      case 'readOnly':
        return SubscriptionRecordStatus.readOnly;
      case 'active':
      default:
        return SubscriptionRecordStatus.active;
    }
  }
}

/// ===============================
/// PLAN CATALOG  (GET /plans)
/// ===============================

class PlanMonthlyBilling {
  final int price;
  final String currency;

  const PlanMonthlyBilling({required this.price, required this.currency});

  factory PlanMonthlyBilling.fromJson(Map<String, dynamic> json) {
    return PlanMonthlyBilling(
      price: json['price'] ?? 0,
      currency: json['currency'] ?? 'INR',
    );
  }
}

class PlanAnnualBilling {
  final int price;
  final int strikePrice;
  final int discountPercentage;
  final String currency;

  const PlanAnnualBilling({
    required this.price,
    required this.strikePrice,
    required this.discountPercentage,
    required this.currency,
  });

  factory PlanAnnualBilling.fromJson(Map<String, dynamic> json) {
    return PlanAnnualBilling(
      price: json['price'] ?? 0,
      strikePrice: json['strikePrice'] ?? 0,
      discountPercentage: json['discountPercentage'] ?? 0,
      currency: json['currency'] ?? 'INR',
    );
  }
}

/// Either side may be null (see [PlanCatalogItem] -- Trial has neither).
class PlanBilling {
  final PlanMonthlyBilling? monthly;
  final PlanAnnualBilling? annual;

  const PlanBilling({this.monthly, this.annual});

  factory PlanBilling.fromJson(Map<String, dynamic> json) {
    return PlanBilling(
      monthly: json['monthly'] != null
          ? PlanMonthlyBilling.fromJson(json['monthly'])
          : null,
      annual: json['annual'] != null
          ? PlanAnnualBilling.fromJson(json['annual'])
          : null,
    );
  }
}

/// `null` on either field means "Unlimited" -- the UI renders that word
/// itself on a null value; it must never be hardcoded against a
/// specific plan id (e.g. "Enterprise always says Unlimited") since
/// that's exactly the kind of per-plan-id assumption the contract warns
/// against baking into the widget tree.
class PlanLimits {
  final int? maxUsers;
  final int? maxBranches;

  const PlanLimits({required this.maxUsers, required this.maxBranches});

  factory PlanLimits.fromJson(Map<String, dynamic> json) {
    return PlanLimits(
      maxUsers: json['maxUsers'] as int?,
      maxBranches: json['maxBranches'] as int?,
    );
  }
}

class PlanFeatureFlags {
  final bool fullReportsPnl;
  final bool emailInvites;
  final bool whiteLabelBranding;
  final bool apiAccess;

  const PlanFeatureFlags({
    required this.fullReportsPnl,
    required this.emailInvites,
    required this.whiteLabelBranding,
    required this.apiAccess,
  });

  factory PlanFeatureFlags.fromJson(Map<String, dynamic> json) {
    return PlanFeatureFlags(
      fullReportsPnl: json['fullReportsPnl'] ?? false,
      emailInvites: json['emailInvites'] ?? false,
      whiteLabelBranding: json['whiteLabelBranding'] ?? false,
      apiAccess: json['apiAccess'] ?? false,
    );
  }
}

class PlanCatalogItem {
  final TenantPlan planId;
  final String name;
  final String description;
  final bool isFree;
  final bool recommended;
  final String? badge;
  final PlanBilling billing;
  final PlanLimits limits;
  final PlanFeatureFlags features;

  const PlanCatalogItem({
    required this.planId,
    required this.name,
    required this.description,
    required this.isFree,
    required this.recommended,
    required this.badge,
    required this.billing,
    required this.limits,
    required this.features,
  });

  factory PlanCatalogItem.fromJson(Map<String, dynamic> json) {
    return PlanCatalogItem(
      planId: TenantPlan.fromApiValue(json['planId']),
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      isFree: json['isFree'] ?? false,
      recommended: json['recommended'] ?? false,
      badge: json['badge'] as String?,
      billing: PlanBilling.fromJson(json['billing'] ?? {}),
      limits: PlanLimits.fromJson(json['limits'] ?? {}),
      features: PlanFeatureFlags.fromJson(json['features'] ?? {}),
    );
  }
}

class PlanCatalogResponse {
  final List<PlanCatalogItem> plans;

  const PlanCatalogResponse({required this.plans});

  factory PlanCatalogResponse.fromJson(Map<String, dynamic> json) {
    final plansJson = json['plans'] as List? ?? [];
    return PlanCatalogResponse(
      plans: plansJson.map((e) => PlanCatalogItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// PER-ORG SUBSCRIPTION STATUS
/// (GET /organizations/{orgId}/subscription)
/// ===============================

class OrganizationSummary {
  final String id;
  final String code;
  final String name;
  final TenantPlan plan;
  final TenantStatus status;
  final DateTime? trialExpiresAt;
  final DateTime? planExpiresAt;
  final int userCount;
  final int branchCount;

  const OrganizationSummary({
    required this.id,
    required this.code,
    required this.name,
    required this.plan,
    required this.status,
    required this.trialExpiresAt,
    required this.planExpiresAt,
    required this.userCount,
    required this.branchCount,
  });

  factory OrganizationSummary.fromJson(Map<String, dynamic> json) {
    return OrganizationSummary(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      plan: TenantPlan.fromApiValue(json['plan']),
      status: TenantStatus.fromApiValue(json['status']),
      trialExpiresAt: json['trialExpiresAt'] != null
          ? DateTime.tryParse(json['trialExpiresAt'])
          : null,
      planExpiresAt: json['planExpiresAt'] != null
          ? DateTime.tryParse(json['planExpiresAt'])
          : null,
      userCount: json['userCount'] ?? 0,
      branchCount: json['branchCount'] ?? 0,
    );
  }
}

class SubscriptionRecord {
  final String id;
  final String orgId;
  final String adminId;
  final BillingCycle plan;
  final SubscriptionRecordStatus status;
  final bool isReadOnly;
  final DateTime startDate;
  final DateTime expiryDate;

  const SubscriptionRecord({
    required this.id,
    required this.orgId,
    required this.adminId,
    required this.plan,
    required this.status,
    required this.isReadOnly,
    required this.startDate,
    required this.expiryDate,
  });

  factory SubscriptionRecord.fromJson(Map<String, dynamic> json) {
    return SubscriptionRecord(
      id: json['id'] ?? '',
      orgId: json['orgId'] ?? '',
      adminId: json['adminId'] ?? '',
      plan: BillingCycle.fromApiValue(json['plan']),
      status: SubscriptionRecordStatus.fromApiValue(json['status']),
      isReadOnly: json['isReadOnly'] ?? false,
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      expiryDate:
          DateTime.tryParse(json['expiryDate'] ?? '') ?? DateTime.now(),
    );
  }
}

/// `type` is `"info" | "warning" | "danger"` -- reused as-is by
/// [SubscriptionBanner] the widget to pick color/icon, same convention
/// already used for dashboard alert types.
class SubscriptionBannerData {
  final String type;
  final String title;
  final String description;

  const SubscriptionBannerData({
    required this.type,
    required this.title,
    required this.description,
  });

  factory SubscriptionBannerData.fromJson(Map<String, dynamic> json) {
    return SubscriptionBannerData(
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class SubscriptionLastPlan {
  final TenantPlan planId;
  final DateTime? expiredOn;

  const SubscriptionLastPlan({required this.planId, required this.expiredOn});

  factory SubscriptionLastPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionLastPlan(
      planId: TenantPlan.fromApiValue(json['planId']),
      expiredOn: json['expiredOn'] != null
          ? DateTime.tryParse(json['expiredOn'])
          : null,
    );
  }
}

/// First-class fields the backend/mock datasource owns the business
/// logic for -- [remainingDays]/[totalDays] for the ring, [showBanner]/
/// [banner] for the banner copy, [locked]/[renewVerb] for the CTA
/// resolver. Flutter must never derive any of these from date math
/// itself (e.g. computing "days left" from `planExpiresAt - now`) --
/// see the API contract's explicit instruction on this.
class SubscriptionUiMeta {
  final int? remainingDays;
  final int? totalDays;
  final bool showBanner;
  final SubscriptionBannerData? banner;

  /// `"renew" | "support" | null`. `"renew"` = self-serve
  /// renew/reactivate allowed (Expired/Cancelled). `"support"` = locked,
  /// contact-support only (Suspended). `null` = not locked at all.
  final String? locked;

  /// e.g. `"Renew"` or `"Reactivate"` -- substituted into the CTA
  /// resolver's `{renewVerb}` placeholders.
  final String? renewVerb;

  final SubscriptionLastPlan? lastPlan;

  const SubscriptionUiMeta({
    required this.remainingDays,
    required this.totalDays,
    required this.showBanner,
    required this.banner,
    required this.locked,
    required this.renewVerb,
    required this.lastPlan,
  });

  factory SubscriptionUiMeta.fromJson(Map<String, dynamic> json) {
    return SubscriptionUiMeta(
      remainingDays: json['remainingDays'] as int?,
      totalDays: json['totalDays'] as int?,
      showBanner: json['showBanner'] ?? false,
      banner: json['banner'] != null
          ? SubscriptionBannerData.fromJson(json['banner'])
          : null,
      locked: json['locked'] as String?,
      renewVerb: json['renewVerb'] as String?,
      lastPlan: json['lastPlan'] != null
          ? SubscriptionLastPlan.fromJson(json['lastPlan'])
          : null,
    );
  }
}

/// Top-level response for `GET /organizations/{orgId}/subscription`.
/// [organization]/[subscription] are both null only in the
/// first-purchase state (no org exists yet) -- every other state has
/// both populated.
class SubscriptionStatusResponse {
  final OrganizationSummary? organization;
  final SubscriptionRecord? subscription;
  final SubscriptionUiMeta ui;

  const SubscriptionStatusResponse({
    required this.organization,
    required this.subscription,
    required this.ui,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatusResponse(
      organization: json['organization'] != null
          ? OrganizationSummary.fromJson(json['organization'])
          : null,
      subscription: json['subscription'] != null
          ? SubscriptionRecord.fromJson(json['subscription'])
          : null,
      ui: SubscriptionUiMeta.fromJson(json['ui'] ?? {}),
    );
  }
}
