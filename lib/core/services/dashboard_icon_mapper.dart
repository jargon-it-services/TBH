import 'package:flutter/material.dart';

/// Maps the string icon keys the dashboard API sends (e.g.
/// `"design_services"`, `"payments"`) to a Flutter [IconData].
///
/// The merged dashboard response (`quick_insights.items[].icon`,
/// `business_summary.items[].icon`) carries icons as plain strings
/// instead of anything Flutter-specific, so the UI needs a lookup
/// table rather than assuming a fixed, hardcoded set of cards. The
/// keys the backend currently sends resemble Material icon names —
/// this map uses that as its primary strategy — but any unrecognized
/// key safely falls back to [fallback] instead of crashing or leaving
/// a blank space, so a new icon key the app doesn't know about yet
/// never breaks the dashboard.
///
/// Extend [_icons] as new keys show up in real responses.
class DashboardIconMapper {
  DashboardIconMapper._();

  static const Map<String, IconData> _icons = {
    'design_services': Icons.design_services_outlined,
    'payments': Icons.payments_outlined,
    'payment': Icons.payments_outlined,
    'star': Icons.star_rounded,
    'security': Icons.security_rounded,
    'receipt_long': Icons.receipt_long_outlined,
    'trending_up': Icons.trending_up_rounded,
    'trending_down': Icons.trending_down_rounded,
    'store': Icons.storefront_outlined,
    'storefront': Icons.storefront_outlined,
    'spa': Icons.spa_outlined,
    'people': Icons.people_alt_outlined,
    'people_alt': Icons.people_alt_outlined,
    'services': Icons.design_services_outlined,
    'customers': Icons.people_alt_outlined,
    'person': Icons.person_outline,
    'group': Icons.group_outlined,
    'insights': Icons.insights_outlined,
    'analytics': Icons.analytics_outlined,
    'currency_rupee': Icons.currency_rupee_rounded,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'content_cut': Icons.content_cut,
    'schedule': Icons.schedule_outlined,
    'warning': Icons.warning_amber_rounded,
    'info': Icons.info_outline,
    'error': Icons.error_outline,
    'check_circle': Icons.check_circle_outline,
    'notifications': Icons.notifications_none_rounded,
    'inventory': Icons.inventory_2_outlined,
    'pie_chart': Icons.pie_chart_outline,
    'show_chart': Icons.show_chart,
    'calendar': Icons.calendar_today_outlined,
    'card': Icons.credit_card,
    'qr_code': Icons.qr_code_2,
  };

  /// Resolves [key] (case/space insensitive) to an [IconData], falling
  /// back to [fallback] (defaults to a generic dashboard icon) for any
  /// null, empty, or unrecognized key.
  static IconData iconFromKey(String? key, {IconData? fallback}) {
    final resolvedFallback = fallback ?? Icons.dashboard_outlined;
    if (key == null || key.trim().isEmpty) return resolvedFallback;
    return _icons[key.trim().toLowerCase()] ?? resolvedFallback;
  }
}
