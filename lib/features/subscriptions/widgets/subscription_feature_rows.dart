import 'package:flutter/material.dart';

import '../../../core/services/DataModels/subscription_models.dart';

/// One row of the feature comparison -- either a `limit` (numeric,
/// null = "Unlimited") or a `bool` (check/cross). Shared by both
/// [PlanCard]'s condensed feature list and the full comparison table,
/// so a new feature only needs to be added here once.
enum SubscriptionFeatureRowType { limit, boolean }

class SubscriptionFeatureRow {
  final String label;
  final IconData icon;
  final SubscriptionFeatureRowType type;

  /// Reads this row's value off [plan]. Returns an `int?` for [limit]
  /// rows (null = Unlimited) or a `bool` for [boolean] rows.
  final Object? Function(PlanCatalogItem plan) valueOf;

  const SubscriptionFeatureRow({
    required this.label,
    required this.icon,
    required this.type,
    required this.valueOf,
  });
}

/// The full, ordered feature set every plan card / comparison table
/// row is generated from -- matches SRS §3.4 exactly. Adding a new
/// plan feature to the catalog response only requires adding one entry
/// here; nothing else in the UI hardcodes a specific feature per plan.
final List<SubscriptionFeatureRow> subscriptionFeatureRows = [
  SubscriptionFeatureRow(
    label: 'Max Users',
    icon: Icons.people_outline,
    type: SubscriptionFeatureRowType.limit,
    valueOf: (p) => p.limits.maxUsers,
  ),
  SubscriptionFeatureRow(
    label: 'Max Branches',
    icon: Icons.store_outlined,
    type: SubscriptionFeatureRowType.limit,
    valueOf: (p) => p.limits.maxBranches,
  ),
  SubscriptionFeatureRow(
    label: 'Full Reports & P&L',
    icon: Icons.bar_chart_outlined,
    type: SubscriptionFeatureRowType.boolean,
    valueOf: (p) => p.features.fullReportsPnl,
  ),
  SubscriptionFeatureRow(
    label: 'Email Invites',
    icon: Icons.mail_outline,
    type: SubscriptionFeatureRowType.boolean,
    valueOf: (p) => p.features.emailInvites,
  ),
  SubscriptionFeatureRow(
    label: 'White-Label Branding',
    icon: Icons.palette_outlined,
    type: SubscriptionFeatureRowType.boolean,
    valueOf: (p) => p.features.whiteLabelBranding,
  ),
  SubscriptionFeatureRow(
    label: 'API Access',
    icon: Icons.code_rounded,
    type: SubscriptionFeatureRowType.boolean,
    valueOf: (p) => p.features.apiAccess,
  ),
];

/// Formats a [SubscriptionFeatureRowType.limit] value for display --
/// `null` always renders as "Unlimited", never a hardcoded number.
String formatFeatureLimit(int? value) => value == null ? 'Unlimited' : '$value';
