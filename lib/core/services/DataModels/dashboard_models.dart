// dashboard_models.dart
//
// Models for the merged `/dashboard` response used by every role except
// Super Admin (Super Admin keeps its own separate `/dashboard/header` +
// dashboard flow -- see `DashboardHeaderModel` / `DashboardHeaderApi`).
//
// Every optional section below (`important_alerts`, `quick_insights`,
// `business_summary`, `overview_trend`, `revenue_contribution`,
// `recent_transactions`) parses to `null` when the API sends it empty,
// missing, or absent -- callers hide the corresponding section on
// `null`/empty rather than the model inventing placeholder data. This
// is what makes the dashboard "never hardcode visibility of any
// section": visibility is a straight `data != null` check driven by
// what the API actually returned, not a per-role switch in the UI.

import 'dashboard_header_model.dart';

/// ===============================
/// DASHBOARD RESPONSE
/// ===============================

class DashboardResponse {
  final bool status;
  final String message;
  final DashboardData data;

  DashboardResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: DashboardData.fromJson(json['data'] ?? {}),
    );
  }
}

/// ===============================
/// DASHBOARD DATA
/// ===============================

class DashboardData {
  final DashboardMeta meta;
  final DashboardHeaderData dashboardHeader;
  final List<DashboardAlertItem>? importantAlerts;
  final QuickInsights? quickInsights;
  final BusinessSummary? businessSummary;
  final OverviewTrend? overviewTrend;
  final RevenueContribution? revenueContribution;
  final RecentTransactions? recentTransactions;
  final String? lastUpdated;

  DashboardData({
    required this.meta,
    required this.dashboardHeader,
    required this.importantAlerts,
    required this.quickInsights,
    required this.businessSummary,
    required this.overviewTrend,
    required this.revenueContribution,
    required this.recentTransactions,
    required this.lastUpdated,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final alertsJson = json['important_alerts'] as List?;
    final quickInsightsJson = json['quick_insights'] as Map<String, dynamic>?;
    final businessSummaryJson =
        json['business_summary'] as Map<String, dynamic>?;
    final overviewTrendJson = json['overview_trend'] as Map<String, dynamic>?;
    final revenueContributionJson =
        json['revenue_contribution'] as Map<String, dynamic>?;
    final recentTransactionsJson =
        json['recent_transactions'] as Map<String, dynamic>?;

    return DashboardData(
      meta: DashboardMeta.fromJson(json['meta'] ?? {}),
      dashboardHeader: DashboardHeaderData.fromJson(
        json['dashboard_header'] ?? {},
      ),
      importantAlerts: (alertsJson == null || alertsJson.isEmpty)
          ? null
          : alertsJson.map((e) => DashboardAlertItem.fromJson(e)).toList(),
      quickInsights: QuickInsights.fromJsonOrNull(quickInsightsJson),
      businessSummary: BusinessSummary.fromJsonOrNull(businessSummaryJson),
      overviewTrend: OverviewTrend.fromJsonOrNull(overviewTrendJson),
      revenueContribution: RevenueContribution.fromJsonOrNull(
        revenueContributionJson,
      ),
      recentTransactions: RecentTransactions.fromJsonOrNull(
        recentTransactionsJson,
      ),
      lastUpdated: json['last_updated'] as String?,
    );
  }
}

/// ===============================
/// META
/// ===============================

class DashboardPeriodOption {
  final String key;
  final String label;

  const DashboardPeriodOption({required this.key, required this.label});

  factory DashboardPeriodOption.fromJson(Map<String, dynamic> json) {
    return DashboardPeriodOption(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
    );
  }
}

class DashboardMeta {
  final String currency;
  final String currencySymbol;
  final String dateFormat;
  final String timezone;
  final List<DashboardPeriodOption> periods;
  final String selectedPeriod;

  DashboardMeta({
    required this.currency,
    required this.currencySymbol,
    required this.dateFormat,
    required this.timezone,
    required this.periods,
    required this.selectedPeriod,
  });

  factory DashboardMeta.fromJson(Map<String, dynamic> json) {
    return DashboardMeta(
      currency: json['currency'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      dateFormat: json['date_format'] ?? '',
      timezone: json['timezone'] ?? '',
      periods: (json['periods'] as List? ?? [])
          .map((e) => DashboardPeriodOption.fromJson(e))
          .toList(),
      selectedPeriod: json['selected_period'] ?? '',
    );
  }
}

/// ===============================
/// DASHBOARD HEADER (merged-response roles only)
/// ===============================

/// The sticky header's data as it now arrives inside the merged
/// `/dashboard` response, for every role except Super Admin (which
/// still uses `DashboardHeaderModel` via the standalone header API).
/// [branches] reuses [BranchModel] from `dashboard_header_model.dart`
/// rather than a duplicate model, since the wire shape (id/name/code)
/// is identical.
class DashboardHeaderData {
  final String accountName;
  final String accountCode;
  final String roleLabel;
  final int notificationCount;
  final String profileInitials;
  final List<BranchModel> branches;

  DashboardHeaderData({
    required this.accountName,
    required this.accountCode,
    required this.roleLabel,
    required this.notificationCount,
    required this.profileInitials,
    required this.branches,
  });

  factory DashboardHeaderData.fromJson(Map<String, dynamic> json) {
    return DashboardHeaderData(
      accountName: json['account_name'] ?? '',
      accountCode: json['account_code'] ?? '',
      roleLabel: json['role_label'] ?? '',
      notificationCount: json['notification_count'] ?? 0,
      profileInitials: json['profile_initials'] ?? '',
      branches: (json['branches'] as List? ?? [])
          .map((e) => BranchModel.fromJson(e))
          .toList(),
    );
  }
}

/// ===============================
/// IMPORTANT ALERTS
/// ===============================

class DashboardAlertAction {
  final String label;
  final String? screen;

  const DashboardAlertAction({required this.label, this.screen});

  factory DashboardAlertAction.fromJson(Map<String, dynamic> json) {
    return DashboardAlertAction(
      label: json['label'] ?? '',
      screen: json['screen'] as String?,
    );
  }
}

class DashboardAlertItem {
  final dynamic id;
  final String type;
  final String title;
  final String description;
  final DashboardAlertAction? action;

  const DashboardAlertItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.action,
  });

  factory DashboardAlertItem.fromJson(Map<String, dynamic> json) {
    return DashboardAlertItem(
      id: json['id'],
      type: json['type'] ?? 'info',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      action: json['action'] != null
          ? DashboardAlertAction.fromJson(json['action'])
          : null,
    );
  }
}

/// ===============================
/// QUICK INSIGHTS
/// ===============================

/// One [QuickInsights] item. Exactly one of [value] (a single figure,
/// e.g. Total Revenue) or [values] (several named sub-figures shown
/// side by side, e.g. Services + Customers) is expected to be
/// non-null -- never assume which, always check both.
class QuickInsightItem {
  final String key;
  final String title;
  final String? icon;
  final num? value;
  final Map<String, num>? values;

  const QuickInsightItem({
    required this.key,
    required this.title,
    this.icon,
    this.value,
    this.values,
  });

  factory QuickInsightItem.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];
    return QuickInsightItem(
      key: json['key'] ?? '',
      title: json['title'] ?? '',
      icon: json['icon'] as String?,
      value: json['value'] as num?,
      values: rawValues is Map
          ? rawValues.map((k, v) => MapEntry(k.toString(), (v as num?) ?? 0))
          : null,
    );
  }
}

class QuickInsights {
  final String title;
  final List<QuickInsightItem> items;

  const QuickInsights({required this.title, required this.items});

  static QuickInsights? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final itemsJson = json['items'] as List?;
    if (itemsJson == null || itemsJson.isEmpty) return null;
    return QuickInsights(
      title: json['title'] ?? 'Quick Insights',
      items: itemsJson.map((e) => QuickInsightItem.fromJson(e)).toList(),
    );
  }
}

/// ===============================
/// BUSINESS SUMMARY
/// ===============================

/// [value] is intentionally `dynamic`: the API sends either a number
/// (formatted as currency by the UI) or a string (displayed as-is) --
/// see the formatting helper at the call site.
class BusinessSummaryItemData {
  final String title;
  final String? icon;
  final dynamic value;

  const BusinessSummaryItemData({
    required this.title,
    this.icon,
    required this.value,
  });

  factory BusinessSummaryItemData.fromJson(Map<String, dynamic> json) {
    return BusinessSummaryItemData(
      title: json['title'] ?? '',
      icon: json['icon'] as String?,
      value: json['value'],
    );
  }
}

class BusinessSummary {
  final String title;
  final List<BusinessSummaryItemData> items;

  const BusinessSummary({required this.title, required this.items});

  static BusinessSummary? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final itemsJson = json['items'] as List?;
    if (itemsJson == null || itemsJson.isEmpty) return null;
    return BusinessSummary(
      title: json['title'] ?? 'Business Summary',
      items:
          itemsJson.map((e) => BusinessSummaryItemData.fromJson(e)).toList(),
    );
  }
}

/// ================= TREND MODELS =================

class TrendPoint {
  final String key;
  final String label;
  final double value;

  TrendPoint({
    required this.key,
    required this.label,
    required this.value,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    final num rawValue = json['value'] ?? 0;

    return TrendPoint(
      key: json['key'] ?? '',
      label: json['label'] ?? '',
      value: rawValue.isFinite ? rawValue.toDouble() : 0,
    );
  }
}

class OverviewTrend {
  final String title;
  final String period;
  final int visiblePoints;
  final bool hasMoreData;
  final String range;
  final List<TrendPoint> points;
  final String? nextCursor;
  final String? prevCursor;

  OverviewTrend({
    required this.title,
    required this.period,
    required this.visiblePoints,
    required this.hasMoreData,
    required this.range,
    required this.points,
    required this.nextCursor,
    required this.prevCursor,
  });

  static OverviewTrend? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final pointsJson = json['points'] as List?;
    if (pointsJson == null || pointsJson.isEmpty) return null;
    return OverviewTrend(
      title: json['title'] ?? 'Revenue Trend',
      period: json['period'] ?? '',
      visiblePoints: json['visible_points'] ?? pointsJson.length,
      hasMoreData: json['has_more_data'] ?? false,
      range: json['range'] ?? '',
      points: pointsJson.map((e) => TrendPoint.fromJson(e)).toList(),
      nextCursor: json['next_cursor'],
      prevCursor: json['prev_cursor'],
    );
  }
}

/// ================= REVENUE CONTRIBUTION =================

class RevenueContributionItemData {
  final dynamic id;
  final String label;
  final double value;

  const RevenueContributionItemData({
    required this.id,
    required this.label,
    required this.value,
  });

  factory RevenueContributionItemData.fromJson(Map<String, dynamic> json) {
    return RevenueContributionItemData(
      id: json['id'],
      label: json['label'] ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueContribution {
  final String title;
  final List<RevenueContributionItemData> items;

  const RevenueContribution({required this.title, required this.items});

  static RevenueContribution? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final itemsJson = json['items'] as List?;
    if (itemsJson == null || itemsJson.isEmpty) return null;
    return RevenueContribution(
      title: json['title'] ?? 'Revenue Contribution',
      items: itemsJson
          .map((e) => RevenueContributionItemData.fromJson(e))
          .toList(),
    );
  }
}

/// ================= RECENT TRANSACTIONS =================

class DashboardTransactionItem {
  final String id;
  final String invoiceNo;
  final String customerName;
  final String service;
  final String branch;
  final double amount;
  final String paymentMode;
  final String status;
  final String? transactionDate;

  const DashboardTransactionItem({
    required this.id,
    required this.invoiceNo,
    required this.customerName,
    required this.service,
    required this.branch,
    required this.amount,
    required this.paymentMode,
    required this.status,
    required this.transactionDate,
  });

  factory DashboardTransactionItem.fromJson(Map<String, dynamic> json) {
    return DashboardTransactionItem(
      id: (json['id'] ?? '').toString(),
      invoiceNo: json['invoice_no'] ?? '',
      customerName: json['customer_name'] ?? '',
      service: json['service'] ?? '',
      branch: json['branch'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentMode: json['payment_mode'] ?? '',
      status: json['status'] ?? '',
      transactionDate: json['transaction_date'] as String?,
    );
  }
}

class RecentTransactions {
  final String title;
  final int count;
  final List<DashboardTransactionItem> items;

  const RecentTransactions({
    required this.title,
    required this.count,
    required this.items,
  });

  static RecentTransactions? fromJsonOrNull(Map<String, dynamic>? json) {
    if (json == null) return null;
    final itemsJson = json['items'] as List?;
    if (itemsJson == null || itemsJson.isEmpty) return null;
    final items =
        itemsJson.map((e) => DashboardTransactionItem.fromJson(e)).toList();
    return RecentTransactions(
      title: json['title'] ?? 'Recent Transactions',
      count: json['count'] ?? items.length,
      items: items,
    );
  }
}
